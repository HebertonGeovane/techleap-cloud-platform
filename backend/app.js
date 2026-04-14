const express = require('express');
const { Pool } = require('pg');
const cors = require('cors'); 
const app = express();

app.use(express.json());
app.use(cors({
  origin: '*', 
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type']
})); 

const client = require('prom-client');
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ register: client.register });

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

const pool = new Pool({
  host: process.env.DB_HOST || 'db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'senha_local',
  database: 'techleapdb',
  port: 5432,
});

const conectarComRetry = () => {
  pool.query(`
    CREATE TABLE IF NOT EXISTS candidaturas (
      id SERIAL PRIMARY KEY,
      vaga_id VARCHAR(100),
      nome_candidato VARCHAR(255),
      email VARCHAR(255),
      pretensao_salarial VARCHAR(50),
      arquivo_cv VARCHAR(255),
      data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `)
  .then(() => console.log("✅ Conectado ao Banco e Tabela Pronta!"))
  .catch(err => {
    console.error("❌ Banco ainda não está pronto, tentando novamente...");
    setTimeout(conectarComRetry, 5000);
  });
};


conectarComRetry();

app.post('/candidatar', async (req, res) => {
  const { vaga_id, nome, email, salario, arquivo_cv } = req.body;
  try {
    await pool.query(
      'INSERT INTO candidaturas (vaga_id, nome_candidato, email, pretensao_salarial, arquivo_cv) VALUES ($1, $2, $3, $4, $5)',
      [vaga_id, nome, email, salario, arquivo_cv]
    );
    res.status(200).send({ message: "Gravado com sucesso!" });
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.listen(3000, () => console.log('🚀 Backend rodando na porta 3000'));