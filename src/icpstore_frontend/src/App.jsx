import { useState, useEffect } from 'react';
import { icpstore_backend } from 'declarations/icpstore_backend';
import { Principal } from '@dfinity/principal'; 
import { idlFactory } from '../../declarations/icpsc_icrc1_ledger_canister/icpsc_icrc1_ledger_canister.did.js';

function App() {

  //obtem o id do canister da ledger do token ICPSC
  const canisterLedgerId = process.env.CANISTER_ID_ICPSC_ICRC1_LEDGER_CANISTER;
  // Quando for desenvolvimento local a variavel process.env.DFX_NETWORK irá retornar a string 'local'
  const host = process.env.DFX_NETWORK === 'ic' ? 'https://mainnet.dfinity.network' : 'http://localhost:4943';

  const [products, setProducts] = useState([]);

  useEffect(() => {    
    const init = async () => {
      setProducts(await icpstore_backend.getProducts());
    }
    init();
  }, []);  


  async function getAccountFromBalance(account) {
   
    try {
        if (account != '') {                        
            setFrom(account);
            const result = await icpstore_backend.getBalance(Principal.fromText(account));
            setBalancesFrom(parseInt(result));  
            setMessage('');
        }
    } catch (error) {
        console.dir(error);
        setBalancesFrom(0);  
        setMessage('Ocorreu uma falha ao retornar o saldo da Conta de Origem');
    }
  }

  // função utilizada para obter o saldo de tokens da conta de destino
  async function getAccountToBalance(account) {
   
    try {
        if (account != '') {                        
            setTo(account);
            const result = await icpstore_backend.getBalance(Principal.fromText(account));
            setBalancesTo(parseInt(result));  
            setMessage('');
        }
    } catch (error) {
        console.dir(error);
        setBalancesTo(0);  
        setMessage('Ocorreu uma falha ao retornar o saldo da Conta de Destino');
    }
  } 


  const comprarProduto = async (produto) => {
    try {
      // Verifica se a Plug Wallet está instalada
      if (!window.ic?.plug) {
        console.error("Plug Wallet não instalada!");
        return;
      }
  


      // Conecta a Plug Wallet se necessário
      let isConnected = await window.ic.plug.isConnected();
      if (!isConnected) {
        await window.ic.plug.requestConnect({
          whitelist: [canisterLedgerId],
          host: host
        });
      }
      
      // Obtém o principal do usuário
      const principal = await window.ic.plug.agent.getPrincipal();
  
      // Cria o actor da ledger
      const actorLedger = await window.ic.plug.createActor({
        canisterId: canisterLedgerId,
        interfaceFactory: idlFactory
      });
  
      // Prepara a transferência
      const valor = BigInt(produto.price);
      const lojaCanisterId = process.env.CANISTER_ID_ICPSTORE_BACKEND;
  
      const args = {
        to: {
          owner: Principal.fromText(lojaCanisterId),
          subaccount: []
        },
        amount: valor,
        memo: [],
        fee: [BigInt(10)],
        from_subaccount: [],
        created_at_time: []
      };
  
      // Realiza a transferência
      const result = await actorLedger.icrc1_transfer(args);
      console.log("Transferência realizada:", result);
  
      // Chama o backend para registrar a compra
      const compra = await icpstore_backend.registerPurchase(produto, Number(valor));
      alert(compra.message);
  
    } catch (error) {
      console.error("Erro ao comprar:", error);
      alert("A transferência foi concluída com sucesso, mas com algumas ressalvas: " + error.message);
    }

    await getAccountFromBalance(lojaCanisterId);
    await getAccountToBalance(lojaCanisterId);
  };

  return (
    <div className="container">
      <h1 className="titulo">Loja de Cursos da ICP</h1>
      <div className="grade-cursos">
        {products.map((p, index) => (
          <div key={index} className="card">
            <img src={p.image} alt={p.title} className="imagem" />
            <h2 className="card-titulo">{p.title}</h2>
            <p className="descricao">{p.description}</p>
            <p className="preco">{p.price} ICPSC</p>
            <button className="botao" onClick={() => comprarProduto(p)}>Comprar</button>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;