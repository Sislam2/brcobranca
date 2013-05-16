# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Febrabam < Base # Banco do Brasil

      #validates_length_of :agencia, :maximum => 4, :message => "deve ser menor ou igual a 4 dígitos."
      #validates_length_of :conta_corrente, :maximum => 8, :message => "deve ser menor ou igual a 8 dígitos."
      #validates_length_of :carteira, :maximum => 2, :message => "deve ser menor ou igual a 2 dígitos."
      #validates_length_of :convenio, :in => 4, :message => "deve ser igual a 4 digitos."
    
      #validates_length_of :numero_documento, :maximum => 17, :message => "deve conter ao menos um digito."

      # Nova instancia do BancoBrasil
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos={})
        campos = {:moeda=> 9 ,:carteira => "18", :codigo_servico => false}.merge!(campos)
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
        quantidade = @numero_documento.to_s.size
        quantidade ? @numero_documento.to_s.rjust((18-quantidade),'0') : @numero_documento
      end

      # Codigo de barras do boleto
      #
      # O codigo de barra contém 44 posições dispostas:
      #def codigo_barras_sem_digitos_verrificadores
      #  "#{codigo_barras_primeira_parte}#{digito_verificador}#{codigo_barras_segunda_parte}"
      #end
      # Monta a segunda parte do código de barras, que é específico para cada banco.
      #
      # @abstract Deverá ser sobreescrito para cada banco.
      def codigo_barras_segunda_parte
	"#{valor_documento_formatado}#{self.convenio}20130517#{self.numero_documento}"
        #"#{valor_documento_formatado}#{self.convenio}#{(DateTime.parse('date') + self.dias_vencimento.days).to_date.strftime("%Y%m%d")}#{self.numero_documento}"
      end
      
    end
  end
end