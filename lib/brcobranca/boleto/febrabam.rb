# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Febrabam < Base # Banco do Brasil

      #validates_length_of :agencia, :maximum => 4, :message => "deve ser menor ou igual a 4 dígitos."
      #validates_length_of :conta_corrente, :maximum => 8, :message => "deve ser menor ou igual a 8 dígitos."
      #validates_length_of :carteira, :maximum => 2, :message => "deve ser menor ou igual a 2 dígitos."
      validates_length_of :convenio, :in => 4, :message => "deve ser igual a 4 digitos."
    
      validates_length_of :numero_documento, :in => 1..17, :message => "deve conter ao menos um digito."

      # Nova instancia do BancoBrasil
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos={})
        campos = {:carteira => "18", :codigo_servico => false}.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        ""
      end

      # Carteira
      #
      # @return [String] 2 caracteres numéricos.
      def carteira=(valor)
        @carteira = valor.to_s.rjust(2,'0') if valor
      end

      # Dígito verificador do banco
      #
      # @return [String] 1 caracteres numéricos.
      def banco_dv
        self.banco.modulo11_9to2_10_como_x
      end

      # Retorna dígito verificador da agência
      #
      # @return [String] 1 caracteres numéricos.
      def agencia_dv
        self.agencia.modulo11_9to2_10_como_x
      end

      # Conta corrente
      # @return [String] 8 caracteres numéricos.
      def conta_corrente=(valor)
        @conta_corrente = valor.to_s.rjust(8,'0') if valor
      end

      # Dígito verificador da conta corrente
      # @return [String] 1 caracteres numéricos.
      def conta_corrente_dv
        self.conta_corrente.modulo11_9to2_10_como_x
      end

      # Número seqüencial utilizado para identificar o boleto.
      # (Número de dígitos depende do tipo de convênio).
      # @raise  [Brcobranca::NaoImplementado] Caso o tipo de convênio não seja suportado pelo Brcobranca.
      #
      # @overload numero_documento
      #   Nosso Número de 17 dígitos com Convenio de 8 dígitos.
      #   @return [String] 9 caracteres numéricos.
      # @overload numero_documento
      #   Nosso Número de 17 dígitos com Convenio de 7 dígitos.
      #   @return [String] 10 caracteres numéricos.
      # @overload numero_documento
      #   Nosso Número de 7 dígitos com Convenio de 4 dígitos.
      #   @return [String] 4 caracteres numéricos.
      # @overload numero_documento
      #   Nosso Número de 11 dígitos com Convenio de 6 dígitos e {#codigo_servico} false.
      #   @return [String] 5 caracteres numéricos.
      # @overload numero_documento
      #   Nosso Número de 17 dígitos com Convenio de 6 dígitos e {#codigo_servico} true. (carteira 16 e 18)
      #   @return [String] 17 caracteres numéricos.
      def numero_documento
        quantidade = case @convenio.to_s.size
        when 8
          9
        when 7
          10
        when 4
          7
        when 6
          self.codigo_servico ? 17 : 5
        else
          raise Brcobranca::NaoImplementado.new("Tipo de convênio não implementado.")
        end
        quantidade ? @numero_documento.to_s.rjust(quantidade,'0') : @numero_documento
      end

      # Dígito verificador do nosso número.
      # @return [String] 1 caracteres numéricos.
      # @see BancoBrasil#numero_documento
      def nosso_numero_dv
        "#{self.convenio}#{self.numero_documento}".modulo11_9to2_10_como_x
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "12387989000004042-4"
      def nosso_numero_boleto
        "#{self.convenio}#{self.numero_documento}-#{self.nosso_numero_dv}"
      end

      # Agência + conta corrente do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0548-7 / 00001448-6"
      def agencia_conta_boleto
        "#{self.agencia}-#{self.agencia_dv} / #{self.conta_corrente}-#{self.conta_corrente_dv}"
      end

      # Segunda parte do código de barras.
      # @return [String] 40 caracteres numéricos.
      def codigo_barras_segunda_parte
        "#{valor_documento_formatado}#{self.convenio}#{(DataTime.now + self.data_vencimento.days).to_date.strftime("%Y%m%d")}#{self.numero_documento}"
      end
      
      # Monta a primeira parte do código de barras.
      # Codigo padrão sendo
      # Posição |Tamanho |Conteúdo<br/>
      # 01 a 01 | 1  | Identificação do Produto Constante “8” para identificar arrecadação<br/>
      # 02 a 02 | 1  | Identificação do Segmento "1" Prefeituras;<br/>
      # 03 a 03 | 1  | Identificador de Valor Efetivo ou Referência "6" utiliza modulo de conversão 10<br/>
      # @return [String] 3 caracteres numéricos.
      def codigo_barras_primeira_parte
        "816"
      end
      
      def digito_verificador
        raise Brcobranca::BoletoInvalido.new(self) unless self.valid?
        codigo = codigo_barras_primeira_parte #18 digitos
        codigo << codigo_barras_segunda_parte #25 digitos
        if codigo =~ /^(\d{3})(\d{40})$/
          codigo_dv = codigo.modulo10
        else
          raise Brcobranca::BoletoInvalido.new(self)
        end
      end

      # Codigo de barras do boleto
      #
      # O codigo de barra contém 44 posições dispostas:
      def codigo_barras_sem_digitos_verrificadores
        "#{codigo_barras_primeira_parte}#{digito_verificador}#{codigo_barras_segunda_parte}"
      end
      
      
      #Codigo de barras completo
      #
      #adicona para cada grupo de 11 digitos do codigo de barras o seu digito verificador no modulo 10
      def codigo_barras
        parte_codigo_11_digito = codigo_barras_sem_digitos_verrificadores.scan(/.........../)
        parte_codigo_11_digito.each do |add_dv|
          add_dv.concat(add_dv.modulo10)
        end
        parte_codigo_11_digito
      end

    end
  end
end