// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

contract Subasta {

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    bool public subastaTerminada;
    bool habilitarDevoluciones;
    uint256 public ofertaBase;
    uint256 private tiempoDuracionSubasta;
    uint256 private tiempoInicioSubasta;
    address payable private direccionOwner;
    mapping(address => uint256) private depositos;

    // tambien almaceno la direccion del ofertante. 
    // Ya que seria el ganador hasta el momento al ser cada oferta mayor a la anterior.
    address private ganadorDireccion;
 
    // archivar direcciones y array de ofertas por cada oferente
    mapping(address => uint256[]) private ofertas;
    
    // struct de ofertas
    struct  Ofertas {
        address oferente;
        uint256 valorOferta;
    }
    Ofertas private oferta;
    
    Ofertas[] private matriz_ofertas;

    function setOferente(address oferente, uint256 valor) private{
        matriz_ofertas.push(Ofertas(oferente,valor));
    }

    //constructor de estado inicial de la subasta
    constructor() {
        subastaTerminada=false;
        habilitarDevoluciones=false;
        ofertaBase = 1 ether; // oferta base o minima 1 Ether
        tiempoDuracionSubasta = block.timestamp + 60 * 60 * 24 * 3; // 3 dias
        tiempoInicioSubasta = block.timestamp; // la subasta inicia al crear el contrato
        direccionOwner = payable(msg.sender); // direccion del Owner o Subastador. No es la del contrato
    }

    // almaceno la oferta mas alta en todo momento. Empiezo con 1 (ofertaBase)
    
    uint256 private ofertaMasAlta = ofertaBase;

    // Eventos:
    //    Nueva Oferta: Se emite cuando se realiza una nueva oferta.
    //    Subasta Finalizada: Se emite cuando finaliza la subasta. Muestra la oferta mas alta y el ganador
    //    VerOfertantes: Se emite al ejecutar la funcion VerTodasLasOfertas()

    event NuevaOferta(uint256 valor, address indexed ofertante);
    event SubastaFinalizada(address ganador, uint256 ofertaGanadora);
    event VerOfertantes(address ofertante, uint256[] ofertas);


    // a) toda nueva oferta tiene que ser mayor a la mas alta hasta el momento más un 5%
    modifier esMayorOferta(uint256 valor) {
        require(valor > (ofertaMasAlta * 105) / 100,"la oferta no supera por 5% a la mas alta");
        _;
    }

    // b) es dueño o subastador
    modifier isOwner() {
        require(msg.sender == direccionOwner,"no es Owner. Acceso restringido");
        _;
    }

    // c) no es dueño
    modifier notOwner() {
        require(msg.sender != direccionOwner,"es Owner. No puede ofertar");
        _;
    }

    // d) subasta finalizada
    modifier subastaTiempoFinalizado(){
        require(block.timestamp>=tiempoDuracionSubasta,"subasta no finalizo .Intentar mas tarde");
        _;
    }

    // e) subasta no finalzada ni terminada por el subastador

     modifier subastaNoTerminada(){
        require(subastaTerminada==false,"subasta finalizada");
        _;
    }

    //f) ver si estan habilitadas las devoluciones 

     modifier devolucionesHabilitadas(){
        require(habilitarDevoluciones==true,"devoluciones cerradas");
        _;
    }
    //g) no es el ganador de la subasta 

     modifier isNotGanador(address direccion){
        require(direccion!=ganadorDireccion,"el ganador de la subasta no puede retirar el deposito total");
        _;
    }

    
    // FUNCION de OFERTAR
    function OFERTAR() 
        public
        payable
        esMayorOferta(msg.value)
        notOwner
        subastaNoTerminada
    {
        // chequeo si el tiempo de  la subasta finalizó
        if (block.timestamp >= tiempoDuracionSubasta) {
            emit SubastaFinalizada(ganadorDireccion, ofertaMasAlta);
            subastaTerminada=true;
            return; // o utilizar revert() ? 
        }

        depositos[msg.sender] +=msg.value; // actualizo el deposito del ofertante 

        setOferente(msg.sender,msg.value);

        ofertas[msg.sender].push(msg.value); // agrego al array ofertas
             
        ofertaMasAlta = msg.value; // almaceno la oferta mas alta hasta este momento
        ganadorDireccion = msg.sender; // almaceno la direccion del ganador hasta este momento

        //aumento de 10 minutos el tiempoDuracionSubasta (10 min = 3600 * 10 segundos).
        //Ver que falten al menos 10 min al fin de la subasta
        if(tiempoDuracionSubasta-block.timestamp>60*10){
            tiempoDuracionSubasta += 60 * 10;   // tiempo de 10 minutos adicionales
        }
        emit NuevaOferta(msg.value, msg.sender); // evento oferta y ofertante
    }

    // FUNCION DE FINALIZAR SUBASTA (unicamnete el subastador o owner y con el tiempo finalizado)

    function finalizarSubasta() 
    public
    isOwner
    //subastaTiempoFinalizado
     {
       subastaTerminada=true;
       habilitarDevoluciones=true;
       emit SubastaFinalizada(ganadorDireccion, ofertaMasAlta);
    
        }
    

// FUNCION DE RETORNO FONDOS AL FINALIZAR LA SUBASTA (la ejecuta cada oferente)


    function retornarDeposito() 
    public   
    payable
    subastaTiempoFinalizado 
    devolucionesHabilitadas
    isNotGanador(msg.sender)
    
    {
        uint256 monto=depositos[msg.sender];
        require(monto>0,"no tiene suficientes fondos para retirar");
        
        uint256 comision = (monto*2)/100;
        uint256 montoADevolver=monto - comision; // la comision queda en el balance del contrato (address(this))

        depositos[msg.sender]=0;
        
        
        (bool sent,) = msg.sender.call{value: montoADevolver}(""); 
        require(sent, "falla en la transaccion");
        
           
    }

// FUNCION DE RETORNO DEPOSITOS PARCIALES
// Pueden retirar hasta el monto de la ultima oferta considerando la retencion del 2%

    function retornarDepositoParciales(uint256 _cantidad) 
    public   
    payable 
    
    {
        uint256 montoParcial=_cantidad * 1 ether;
        uint256 comision = (montoParcial*2)/100;
        uint256 montoADevolver=montoParcial-comision; // comision queda en el balance del contrato
        

        require(montoParcial<=depositos[msg.sender],"no tiene suficientes fondos para retirar");
        require(depositos[msg.sender]>0,"no tiene fondos");
        require(montoParcial<depositos[msg.sender]-getOfertaMasALtaOferente(msg.sender),
            "puede retirar hasta la oferta ultima. Tener en cuenta el 2% de comision");


        depositos[msg.sender] -= montoParcial; // actualizo el deposito del usuario que retira


        (bool sent,) = msg.sender.call{value: montoADevolver}(""); 
        require(sent, "falla en la transaccion");
         
           
    }



// FUNCIONES AUXILIARES

    function verBalanceContrato() external view isOwner returns (uint256) {
        return address(this).balance;
    }

    function verGanador() external view returns (uint256[] memory,address) {
        return (ofertas[ganadorDireccion],ganadorDireccion);
    }

    function verTodasLasOfertas() external view returns(Ofertas[] memory ){
        return matriz_ofertas;
    }
        
    function verOfertasOferenteActual() public view returns (uint256[] memory) {
        return ofertas[msg.sender];
    }

    function getOfertaMasALtaOferente(address oferente) private view returns(uint256){
        return ofertas[oferente][ofertas[oferente].length-1];
    }

    //function verTimestampActual() private view returns (uint256) {
    //    return block.timestamp;
    //}

    function verTiempoFaltante() public view returns (uint256) {
        if (tiempoDuracionSubasta - block.timestamp >= 0) {
            return tiempoDuracionSubasta - block.timestamp;
        } else {
            return 0;
        }
    }

    function verDepositoOferente() public view returns (uint256) {
        return depositos[msg.sender];
    }
}