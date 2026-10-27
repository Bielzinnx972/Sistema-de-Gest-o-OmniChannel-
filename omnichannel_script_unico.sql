-- OMNICHANNEL - SCRIPT UNICO MySQL 8.0+
-- ATENCAO: apaga e recria o banco omnichannel.
DROP DATABASE IF EXISTS omnichannel;
CREATE DATABASE omnichannel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE omnichannel;

CREATE TABLE clientes (
 id_cliente INT AUTO_INCREMENT PRIMARY KEY, nome VARCHAR(100) NOT NULL,
 email VARCHAR(120) NOT NULL UNIQUE, telefone VARCHAR(20),
 data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE lojas (
 id_loja INT AUTO_INCREMENT PRIMARY KEY, nome VARCHAR(100) NOT NULL,
 cidade VARCHAR(80) NOT NULL, estado CHAR(2) NOT NULL
);
CREATE TABLE produtos (
 id_produto INT AUTO_INCREMENT PRIMARY KEY, nome VARCHAR(100) NOT NULL,
 descricao VARCHAR(255), preco DECIMAL(10,2) NOT NULL,
 ativo BOOLEAN NOT NULL DEFAULT TRUE, CHECK (preco >= 0)
);
CREATE TABLE pedidos (
 id_pedido INT AUTO_INCREMENT PRIMARY KEY, id_cliente INT NOT NULL,
 id_loja INT NOT NULL, data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
 status ENUM('ABERTO','PAGO','CANCELADO') NOT NULL DEFAULT 'ABERTO',
 FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
 FOREIGN KEY (id_loja) REFERENCES lojas(id_loja)
);
CREATE TABLE item_pedido (
 id_item INT AUTO_INCREMENT PRIMARY KEY, id_pedido INT NOT NULL,
 id_produto INT NOT NULL, quantidade INT NOT NULL, preco_unitario DECIMAL(10,2) NOT NULL,
 FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
 FOREIGN KEY (id_produto) REFERENCES produtos(id_produto),
 UNIQUE (id_pedido,id_produto), CHECK (quantidade > 0), CHECK (preco_unitario >= 0)
);
CREATE TABLE pagamentos (
 id_pagamento INT AUTO_INCREMENT PRIMARY KEY, id_pedido INT NOT NULL,
 forma_pagamento ENUM('PIX','CARTAO','DINHEIRO','BOLETO') NOT NULL,
 valor DECIMAL(10,2) NOT NULL, data_pagamento DATETIME DEFAULT CURRENT_TIMESTAMP,
 status ENUM('PENDENTE','APROVADO','RECUSADO') NOT NULL DEFAULT 'PENDENTE',
 FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido), CHECK (valor >= 0)
);
CREATE TABLE estoque (
 id_estoque INT AUTO_INCREMENT PRIMARY KEY, id_loja INT NOT NULL,
 id_produto INT NOT NULL, quantidade INT NOT NULL DEFAULT 0,
 FOREIGN KEY (id_loja) REFERENCES lojas(id_loja),
 FOREIGN KEY (id_produto) REFERENCES produtos(id_produto),
 UNIQUE (id_loja,id_produto), CHECK (quantidade >= 0)
);
CREATE TABLE auditoria_preco (
 id_auditoria INT AUTO_INCREMENT PRIMARY KEY, id_produto INT NOT NULL,
 preco_anterior DECIMAL(10,2) NOT NULL, preco_novo DECIMAL(10,2) NOT NULL,
 alterado_em DATETIME DEFAULT CURRENT_TIMESTAMP, usuario_bd VARCHAR(100) NOT NULL,
 FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

INSERT INTO clientes(nome,email,telefone) VALUES
('Ana Souza','ana.souza@example.com','81990000001'),
('Bruno Lima','bruno.lima@example.com','81990000002'),
('Carla Santos','carla.santos@example.com','81990000003'),
('Diego Alves','diego.alves@example.com','81990000004'),
('Eduarda Costa','eduarda.costa@example.com','81990000005');
INSERT INTO lojas(nome,cidade,estado) VALUES
('Loja Recife Centro','Recife','PE'),('Loja Boa Viagem','Recife','PE'),
('Loja Olinda','Olinda','PE'),('Loja Jaboatao','Jaboatao dos Guararapes','PE'),
('Loja Paulista','Paulista','PE');
INSERT INTO produtos(nome,descricao,preco,ativo) VALUES
('Fone Bluetooth','Fone sem fio',129.90,TRUE),
('Teclado USB','Teclado ABNT2',89.90,TRUE),
('Mouse Optico','Mouse USB',39.90,TRUE),
('Monitor 24','Monitor Full HD',799.90,TRUE),
('Webcam HD','Webcam para chamadas',159.90,TRUE);
INSERT INTO pedidos(id_cliente,id_loja,data_pedido,status) VALUES
(1,1,'2026-10-01 10:00:00','PAGO'),(2,2,'2026-10-02 11:00:00','PAGO'),
(3,3,'2026-10-03 12:00:00','ABERTO'),(4,4,'2026-10-04 13:00:00','PAGO'),
(5,5,'2026-10-05 14:00:00','ABERTO');
INSERT INTO item_pedido(id_pedido,id_produto,quantidade,preco_unitario) VALUES
(1,1,1,129.90),(2,2,1,89.90),(3,3,2,39.90),(4,4,1,799.90),(5,5,1,159.90);
INSERT INTO pagamentos(id_pedido,forma_pagamento,valor,data_pagamento,status) VALUES
(1,'PIX',129.90,'2026-10-01 10:05:00','APROVADO'),
(2,'CARTAO',89.90,'2026-10-02 11:05:00','APROVADO'),
(3,'BOLETO',79.80,'2026-10-03 12:05:00','PENDENTE'),
(4,'PIX',799.90,'2026-10-04 13:05:00','APROVADO'),
(5,'DINHEIRO',159.90,'2026-10-05 14:05:00','PENDENTE');
INSERT INTO estoque(id_loja,id_produto,quantidade) VALUES
(1,1,20),(2,2,15),(3,3,50),(4,4,8),(5,5,12);
INSERT INTO auditoria_preco(id_produto,preco_anterior,preco_novo,alterado_em,usuario_bd) VALUES
(1,119.90,129.90,'2026-09-01 09:00:00','seed'),
(2,79.90,89.90,'2026-09-02 09:00:00','seed'),
(3,34.90,39.90,'2026-09-03 09:00:00','seed'),
(4,749.90,799.90,'2026-09-04 09:00:00','seed'),
(5,149.90,159.90,'2026-09-05 09:00:00','seed');

DELIMITER $$
CREATE PROCEDURE sp_registrar_venda(
 IN p_id_cliente INT, IN p_id_loja INT, IN p_id_produto INT,
 IN p_quantidade INT, IN p_forma_pagamento VARCHAR(20)
)
BEGIN
 DECLARE v_preco DECIMAL(10,2) DEFAULT NULL;
 DECLARE v_estoque INT DEFAULT NULL;
 DECLARE v_pedido INT;
 DECLARE v_total DECIMAL(10,2);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

 IF p_quantidade IS NULL OR p_quantidade <= 0 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Quantidade deve ser maior que zero';
 END IF;
 IF p_forma_pagamento NOT IN ('PIX','CARTAO','DINHEIRO','BOLETO') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Forma de pagamento invalida';
 END IF;
 START TRANSACTION;
 SELECT preco INTO v_preco FROM produtos
  WHERE id_produto=p_id_produto AND ativo=TRUE FOR UPDATE;
 IF v_preco IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Produto inexistente ou inativo';
 END IF;
 SELECT quantidade INTO v_estoque FROM estoque
  WHERE id_loja=p_id_loja AND id_produto=p_id_produto FOR UPDATE;
 IF v_estoque IS NULL OR v_estoque < p_quantidade THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Estoque insuficiente ou produto sem estoque';
 END IF;
 INSERT INTO pedidos(id_cliente,id_loja,status) VALUES(p_id_cliente,p_id_loja,'ABERTO');
 SET v_pedido=LAST_INSERT_ID();
 INSERT INTO item_pedido(id_pedido,id_produto,quantidade,preco_unitario)
  VALUES(v_pedido,p_id_produto,p_quantidade,v_preco);
 SET v_total=v_preco*p_quantidade;
 INSERT INTO pagamentos(id_pedido,forma_pagamento,valor,status)
  VALUES(v_pedido,p_forma_pagamento,v_total,'PENDENTE');
 UPDATE estoque SET quantidade=quantidade-p_quantidade
  WHERE id_loja=p_id_loja AND id_produto=p_id_produto;
 COMMIT;
 SELECT v_pedido AS id_pedido_criado, v_total AS total_venda;
END$$
CREATE TRIGGER trg_auditoria_preco AFTER UPDATE ON produtos
FOR EACH ROW
BEGIN
 IF OLD.preco <> NEW.preco THEN
  INSERT INTO auditoria_preco(id_produto,preco_anterior,preco_novo,usuario_bd)
  VALUES(NEW.id_produto,OLD.preco,NEW.preco,CURRENT_USER());
 END IF;
END$$
DELIMITER ;

-- Criacao de usuario e permissao: pode exigir conta administrativa.
CREATE USER IF NOT EXISTS 'omni_app'@'localhost' IDENTIFIED BY 'Troque_Esta_Senha_123!';
GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON omnichannel.* TO 'omni_app'@'localhost';

-- Conferencia: cada tabela deve mostrar total 5.
SELECT 'clientes' tabela,COUNT(*) total FROM clientes
UNION ALL SELECT 'lojas',COUNT(*) FROM lojas
UNION ALL SELECT 'produtos',COUNT(*) FROM produtos
UNION ALL SELECT 'pedidos',COUNT(*) FROM pedidos
UNION ALL SELECT 'item_pedido',COUNT(*) FROM item_pedido
UNION ALL SELECT 'pagamentos',COUNT(*) FROM pagamentos
UNION ALL SELECT 'estoque',COUNT(*) FROM estoque
UNION ALL SELECT 'auditoria_preco',COUNT(*) FROM auditoria_preco;

-- Testes opcionais para executar depois, separadamente:
-- UPDATE produtos SET preco=preco+1 WHERE id_produto=1;
-- SELECT * FROM auditoria_preco ORDER BY id_auditoria DESC;
-- CALL sp_registrar_venda(1,1,1,1,'PIX');
