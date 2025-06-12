/*
- Importação do btoken_icrc1_ledger_canister: será utilizada para interagir com o canister ledger do token criado.
- Importação do Principal: necessária para acessar funcionalidades relacionadas ao principal, como por exemplo Principal.fromActor.
*/

import BtokenLedger "canister:btoken_icrc1_ledger_canister";
import Principal "mo:base/Principal";

// Bibliotecas para retorno operações (Sucesso ou Erro)
import Result "mo:base/Result";
import Error "mo:base/Error";

// Função principal
actor Btoken {
  // Função responsavel por retornar o nome do token
  public func getTokenName(): async Text {
    let name = await BtokenLedger.icrc1_name();
    return name;
  };

  // Função responsavel por retornar o symbol do token ICRC-1
  public func getTokenSymbol(): async Text {
    let symbol = await BtokenLedger.icrc1_symbol();
    return symbol;
  };

  // Função responsavel por retornar o total supply do token ICRC-1
  public func getTokenTotalSupply(): async Nat {
    let totalSupply = await BtokenLedger.icrc1_total_supply();
    return totalSupply;
  };

  // Função responsavel por retornar o taxa de tranferencia do token
  public func getTokenFee(): async Nat {
    let fee = await BtokenLedger.icrc1_fee();
    return fee;
  };

  /*
  O que é um minter?
    O minter é responsável por criar novos tokens, podemos fazer uma analogia 
    com um minerador
  */

  // Função para retornar o Principal ID da identidade minter
  public func getTokenMintingPrincipal(): async Text {
    let mintingAccountOpt = await BtokenLedger.icrc1_minting_account();
    
    switch(mintingAccountOpt){
      case (null) { return "Nenhuma conta de mintagem localizada!"; };
      case (?account){
        // Converte o principal para texto
        return Principal.toText(account.owner);
      };
    };
  };

  // Por fim, vamos criar uma descrição do token ICRC-1
  type TokenInfo = {
    name: Text; // Nome do token completo
    symbol: Text; // Símbolo do token
    totalSupply: Nat; // Quantidade total de tokens em circulação
    fee: Nat; // Taxa de transferência do token
    mintingPrincipal: Text; // Responsável por emitir novos tokens
  };

  public func getTokenInfo(): async TokenInfo {
    let name = await getTokenName();
    let symbol = await getTokenSymbol();
    let totalSupply = await getTokenTotalSupply();
    let fee = await getTokenFee();
    let mintingPrincipal = await getTokenMintingPrincipal();

    let info: TokenInfo = {
      name = name;
      symbol = symbol;
      totalSupply = totalSupply;
      fee = fee;
      mintingPrincipal = mintingPrincipal;
    };

    return info;
  };  

  type TransferArgs = {
    amount: Nat;
    toAccount: BtokenLedger.Account;
  };

  public shared func transfer(args: TransferArgs): async Result.Result<BtokenLedger.BlockIndex, Text> {
    let TransferArgs: BtokenLedger.TransferArg = {
      memo = null;
      amount = args.amount;
      from_subaccount = null;
      fee = null;
      to = args.toAccount;
      created_at_time = null;
    };

    try{
      let transferResult = await BtokenLedger.icrc1_transfer(TransferArgs);

      switch(transferResult){
        case(#Err(transferError)) {
          return #err("Não foi possível transferir fundos: " # debug_show(transferError));
        };
        case(#Ok(BlockIndex)) {return #ok BlockIndex};
      };
    } catch(error : Error){
      return #err("Mensagem de rejeição: " # Error.message(error));
    };
  };

  // Função para obter o saldo de tokens
  public func getBalance(owner: Principal): async Nat {
    let balance = await BtokenLedger.icrc1_balance_of({owner = owner; subaccount = null});
    return balance;
  };

  // Função para obter o principalID
  public query func getCanisterPrincipal() : async Text {
    return Principal.toText(Principal.fromActor(Btoken));
  }; 

  public func getCanisterBalance() : async Nat {
    let owner = Principal.fromActor(Btoken);
    let balance = await getBalance(owner);      
    return balance;
  }; 



  // Transferência no padrão ICRC-2

  public shared(msg) func transferFrom(to: Principal, amount: Nat): async Result.Result<BtokenLedger.BlockIndex, Text> {
    let transferFromArgs: BtokenLedger.TransferFromArgs = {
      spender_subaccount = null;
      from = {owner = msg.caller; subaccount = null};
      to = {owner = to; subaccount = null};
      amount = amount;
      fee = null;
      memo = null;
      created_at_time = null;
    };

    try{
      let transferResult = await BtokenLedger.icrc2_transfer_from(transferFromArgs);
      switch(transferResult){
        case(#Err(transferError)){
          return #err("Não foi possível transferir fundos:\n" # debug_show (transferError));
        };
        case(#Ok(BlockIndex)) { return #ok BlockIndex };
      };
    } catch(error: Error){
        return #err("Mensagem de rejeição: " # Error.message(error));
    };
  };


};
