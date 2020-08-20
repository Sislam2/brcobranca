# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Boleto::Febrabam do
  before do
    @valid_attributes = {
      valor: 1.0,
      moeda: 1,
      cedente: 'Prefeitura de Caxias',
      documento_cedente: '87455531000157',
      sacado: 'Rafael Teste',
      sacado_documento: '12345678900',
      sacado_endereco: 'Endereço tal e coisa',
      agencia: '0810',
      logo: '',
      data_vencimento: (DateTime.now + 30).to_date,
      codigo_unico: '',
      instrucao1: 'Tipo Solicitação',
      instrucao1: 'Atividade',
      instrucao1: 'Porte ',
      instrucao1: 'Potencial',
      codigo_receita: '9',
      conta_corrente: '53678',
      inscricao: '0000000',
      tributo_tipo: '83',
      data_documento: DateTime.now.to_date,
      convenio: 3245,
      competencia: '0000',
      numero_documento: '1',
      produto_segmento_valor_efetivo: '543'
    }
  end

  it 'Gerar boleto' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo.codigo_barras).to eql('54340000000010032452020091800000008300000001')
  end

  it 'Não permitir gerar boleto com atributos inválido' do
    boleto_novo = described_class.new
    expect { boleto_novo.codigo_barras }.to raise_error(Brcobranca::BoletoInvalido)
    expect(boleto_novo.errors.count).to eql(1)
  end  

  it 'Gerar boleto nos formatos válidos com método to_' do
    Brcobranca.configuration.gerador = :rghost_carne
    boleto_novo = described_class.new(@valid_attributes)

    %w(pdf).each do |format|
      file_body = boleto_novo.send("to_#{format}".to_sym)
      tmp_file = Tempfile.new('foobar.' << format)
      tmp_file.puts file_body
      tmp_file.close
      expect(File.exist?(tmp_file.path)).to be_truthy
      expect(File.stat(tmp_file.path).zero?).to be_falsey
      expect(File.delete(tmp_file.path)).to eql(1)
      expect(File.exist?(tmp_file.path)).to be_falsey
    end
  end
end
