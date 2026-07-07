-- ============================================================================
-- 7. POPULATE REFERENCE DIMENSIONS
-- ============================================================================
 
INSERT INTO [dw].[Dim_Status] (status_name, status_description)
VALUES 
    ('canceled', 'Pedido Cancelado'),
    ('approved', 'Pedido Aprovado'),
    ('shipped', 'Pedido Enviado'),
    ('delivered', 'Pedido Entregue'),
    ('processing', 'Em Processamento'),
    ('unavailable', 'Indisponível');
 
INSERT INTO [dw].[Dim_Payment] (payment_type, payment_description)
VALUES 
    ('credit_card', 'Cartão de Crédito'),
    ('boleto', 'Boleto'),
    ('debit_card', 'Cartão de Débito'),
    ('voucher', 'Voucher'),
    ('not_defined', 'Não Definido');
 
GO