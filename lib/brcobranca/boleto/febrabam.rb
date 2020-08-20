module Brcobranca
  module Boleto
    class Febrabam < Base # Banco Itaú

      # Validações
      validates_presence_of :produto_segmento_valor_efetivo, message: 'não pode estar em branco.'
      validates_numericality_of :produto_segmento_valor_efetivo, message: 'não é um número.', allow_nil: true

      # <b>REQUERIDO</b>: logo do boleto customisavel
      attr_accessor :logo
      # <b>REQUERIDO</b>: Código único para geração do boleto
      attr_accessor :codigo_unico
      # <b>REQUERIDO</b>: Código da receita febrabam
      attr_accessor :codigo_receita
      # <b>OPCIONAL</b>: Número sequencial utilizado para identificar o inscrição
      attr_accessor :inscricao
      # <b>OPCIONAL</b>: Número sequencial utilizado para identificar o tributo
      attr_accessor :tributo_tipo
      # <b>OPCIONAL</b>: Número sequencial utilizado para identificar o conpetencia
      attr_accessor :competencia
      attr_accessor :produto_segmento_valor_efetivo

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      # Não usado no febrabam
      def banco
        "000"
      end

      # Conta corrente
      # @return [String] 5 caracteres numéricos.
      # Não usado no febrabam
      def conta_corrente
        "00000"
      end

      def banco_dv
        "0"
      end

      # Código da agencia
      # @return [String] 4 caracteres numéricos.
      # Não usado no febrabam
      def agencia
        "0000"
      end

      # Dígito verificador da agência
      # @return [Integer] 1 caracteres numéricos.
      # Não usado no febrabam
      def agencia_dv
        "0"
      end

      # Dígito verificador da conta corrente
      # @return [Integer] 1 caracteres numéricos.
      # Não usado no febrabam
      def conta_corrente_dv
        "0"
      end

      # Dígito verificador do nosso número
      # @return [Integer] 1 caracteres numéricos.
      # Não usado no febrabam
      def nosso_numero_dv
        "0"
      end

      # Agência + conta corrente do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0811 / 53678-8"
      # Não usado no febrabam
      def agencia_conta_boleto
        ""
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "175/12345678-4"
      # Não usado no febrabam
      def nosso_numero_boleto
        ""
      end

      #CONTEÚDO DO CÓDIGO DE BARRAS NOS DOCUMENTOS
      #Disponível em http://www.febraban.org.br/7Rof7SWg6qmyvwJcFwF7I0aSDf9jyV/sitefebraban/Codbar4-v28052004.pdf acessado em: 03/12/2015
      # Posição | Size | Conteúdo
      # 01 – 01 |  01  | Identificação do Produto
      # 02 – 02 |  01  | Identificação do Segmento
      # 03 – 03 |  01  | Identificação do valor real ou referência
      # 04 – 04 |  01  | Dígito verificador geral (módulo 10 ou 11)
      # 05 – 15 |  11  | Valor
      # 16 – 19 |  04  | Identificação da Empresa/Órgão
      # 20 – 44 |  25  | Campo livre de utilização da Empresa/Órgão
      # 16 – 23 |  08  | CNPJ / MF
      # 24 – 44 |  21  | Campo livre de utilização da Empresa/Órgão

      def codigo_barras
        fail Brcobranca::BoletoInvalido.new(self) unless self.valid?
        codigo = codigo_barras_primeira_parte #3 digitos
        codigo << codigo_barras_segunda_parte #39 digitos
        if codigo =~ /^(\d{3})(\d{40})$/
          codigo_dv = digito_verificador(codigo)
          "#{$1}#{codigo_dv}#{$2}"
        else
          fail Brcobranca::BoletoInvalido.new(self)
        end
      end

      # Codigo da primeira parte do boleto 3 Digitos
      #
      # Posição | Size | Conteúdo
      # 01 – 01 |   1  | Identificação do Produto: Constante "8" - para identificar arrecadação;
      # 02 – 02 |   1  | Identificação do Segmento: Constante "1" - Prefeituras;
      # 03 – 03 |   1  | Identificador de Valor Efetivo ou Referência: Constante "6" - Valor a ser cobrado 'efetivamente' em reais com dígito verificador calculado pelo módulo 10 na quarta posição do Código de Barras e valor com 11 posições (versão 2 e posteriores) sem qualquer alteração;
      def codigo_barras_primeira_parte
        produto_segmento_valor_efetivo        
      end

      # Codigo da segunta parte do boleto
      #
      # Posição | Size | Conteúdo
      # 04 – 04 |  01  | Dígito Verificador Dígito de auto conferência dos dados contidos no Código de Barras.
      def digito_verificador(codigo)
        codigo.modulo10
      end

      # Codigo da segunta parte do boleto
      # 05 – 15 |  11  | Valor Efetivo ou Valor Referência
      #                  Se o campo “03 – Código de Moeda” indicar valor efetivo, este campo deverá conter o valor a ser cobrado.
      #                  Se o campo “03 - Código de Moeda” indicado valor de referência, neste campo poderá conter uma quantidade de moeda, zeros, ou um valor a ser reajustado por um índice, etc...
      # 16 – 19 |  04  | Identificação da Empresa/Órgão
      #                  O campo identificação da Empresa/Órgão terá uma codificação especial para cada segmento.
      #                  Será um código de quatro posições atribuído e controlado pela Febraban, ou as primeiras oito posições do cadastro geral de contribuintes do Ministério da Fazenda.
      #                  É através desta informação que o banco identificará a quem repassar as informações e o crédito.
      #                  Se for utilizado o CNPJ para identificar a Empresa/Órgão, haverá uma redução no seu campo livre que passará a conter 21 posições.
      #                  No caso de utilização do Segmento 9, este campo deverá conter o código de compensação do mesmo, com quatro dígitos.
      #                  Cada banco definirá a forma de identificação da empresa a partir da 20ª posição.
      # 20 – 44 |  25  | Campo livre de utilização da Empresa/Órgão
      #                  Este campo é de uso exclusivo da Empresa/Órgão e será devolvido inalterado.
      #                  Se existir data de vencimento no campo livre, ela deverá vir em primeiro lugar e em formato AAAAMMDD.

      def codigo_barras_segunda_parte
        #       Valor Efetivo        |  Identificação da Empresa      | Campo livre
        "#{valor_documento_formatado}#{identificação_da_empresa_orgao}#{campo_livre}"
      end

      def identificação_da_empresa_orgao
        "#{self.convenio}"
      end

      def campo_livre
        "#{dt_vencimento_boleto}#{numero_documento}"
      end

      def dt_vencimento_boleto
        "#{self.data_vencimento.to_date.strftime("%Y%m%d")}"
      end

      def valor_documento_formatado
        valor_documento.round(2).limpa_valor_moeda.to_s.rjust(11, '0')
      end

      def numero_documento
        @inscricao.to_s.rjust(7,'0') + @tributo_tipo.to_s.rjust(2,'0') + @numero_documento.to_s.rjust(8,'0')
      end

    end
  end
end
