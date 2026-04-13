CREATE TABLE IF NOT EXISTS candidaturas (
    id SERIAL PRIMARY KEY,
    vaga_id VARCHAR(100),
    nome_candidato VARCHAR(255),
    email VARCHAR(255),
    pretensao_salarial VARCHAR(50),
    arquivo_cv VARCHAR(255),
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);