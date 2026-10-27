
use('omnichannel_nosql');

db.getCollection('logs_navegacao').insertMany([
    {
        cliente_id: 101,
        data_hora: new Date(),
        pagina_visitada: "/produto/smartphone-galaxy-s23",
        dispositivo: "Mobile",
        acao: "Clique"
    },
    {
        cliente_id: 102,
        data_hora: new Date(),
        pagina_visitada: "/carrinho",
        dispositivo: "Desktop",
        acao: "Acesso"
    },
    {
        cliente_id: 103,
        data_hora: new Date(),
        pagina_visitada: "/pesquisa?q=notebook",
        dispositivo: "Mobile",
        acao: "Pesquisa"
    }
]);

// Consulta para verificar os documentos inseridos
db.getCollection('logs_navegacao').find({});
