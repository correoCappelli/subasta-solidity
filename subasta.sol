// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

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
    address payable private direccionSubasta;
    mapping(address => uint256) private depositos;

    // almaceno la oferta mas alta en todo momento. Empiezo con 1 (ofertaBase)
    // tambien almaceno la direccion del ofertante. Ya que seria el ganador hasta el momento al ser cada oferta mayor a la anterior.
    uint256 private ofertaMasAlta = ofertaBase;
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
        ofertaBase = 1; // oferta base o minima 1 Ether
        tiempoDuracionSubasta = block.timestamp + 60 * 60; // 1 hora
        tiempoInicioSubasta = block.timestamp; // la subasta inicia al crear el contrato
        direccionSubasta = payable(msg.sender); // direccion de la subasta es payable
    }

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
        require(msg.sender == direccionSubasta,"no es Owner. Acceso restringido");
        _;
    }

    // c) no es dueño
    modifier notOwner() {
        require(msg.sender != direccionSubasta,"es Owner. No puede ofertar");
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

        (bool sent,) = direccionSubasta.call{value: msg.value}("");
        require(sent, "falla en la transaccion");

        setOferente(msg.sender,msg.value);

        ofertas[msg.sender].push(msg.value); // agrego al array ofertas
        depositos[msg.sender] +=msg.value; // actualizo el deposito del ofertante      
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
    
        }
    

// FUNCION DE RETORNO FONDOS AL FINALIZAR LA SUBASTA (la ejecuta el subastador)


    function retornarDeposito(address payable dir) 
    public   
    payable
    //subastaTiempoFinalizado 
    devolucionesHabilitadas
    isOwner
    isNotGanador(dir)
    
    {
        require(msg.value<=depositos[dir],"no tiene suficientes fondos para retirar");
        require(depositos[dir]>0,"no tiene fondos");
        
        (bool sent,) = dir.call{value: (msg.value*98)/100}(""); // retengo el 2% de comision y costos operativos
        require(sent, "falla en la transaccion");
        depositos[dir] -= msg.value; // disminuyo el deposito del ofertante

        //payable(msg.sender).transfer(msg.value);
           
    }

// FUNCION DE RETORNO DEPOSITOS PARCIALES (la ejecuta el subastador a pedido de los ofertantes)
// Pueden retirar hasta el monto de la ultima oferta considerando la retencion del 2%

    function retornarDepositoParciales(address payable dir) 
    public   
    payable 
    isOwner
    
    {
        require(msg.value<=depositos[dir],"no tiene suficientes fondos para retirar");
        require(depositos[dir]>0,"no tiene fondos");
        require((msg.value*102)/100<depositos[dir]-getOfertaMasALtaOferente(dir),
            "puede retirar hasta la oferta ultima. Tener en cuenta el 2% de comision");
        
        (bool sent,) = dir.call{value: (msg.value*98)/100}(""); // retengo el 2% de comision y costos operativos
        require(sent, "falla en la transaccion");
        depositos[dir] -= msg.value; 

        //payable(msg.sender).transfer(msg.value);
           
    }



// FUNCIONES AUXILIARES

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

    function verTimestampActual() private view returns (uint256) {
        return block.timestamp;
    }

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