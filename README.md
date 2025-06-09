# 🏆 Contrato de Subasta en Solidity

## 📜 Introducción  

Este contrato implementa una **subasta descentralizada** en Ethereum, permitiendo a los participantes realizar ofertas en Ether.  
**Nota:** La función `OFERTAR()` es **payable**, lo que significa que las ofertas realizadas se almacenan en `address(this).balance`, el balance del contrato. Puedes verificar el saldo acumulado usando la función auxiliar `verBalanceContrato()`.  

---

## 🏗️ Constructor (`constructor()`)  

El constructor **inicializa** el estado del contrato cuando se despliega en la blockchain.  

🔹 **Variables iniciales**:
- La subasta comienza en **estado activo** (`subastaTerminada = false`).
- Se deshabilitan las **devoluciones** al inicio (`habilitarDevoluciones = false`).
- Se establece una **oferta mínima** de **1 Ether** (`ofertaBase = 1 ether`).
- La duración de la subasta se define en **3 días** (`tiempoDuracionSubasta = block.timestamp + 60 * 60 * 24 * 3`).
- Se guarda la **dirección del subastador** (`direccionOwner = payable(msg.sender)`).
- Se registra el **inicio temporal de la subasta** (`tiempoInicioSubasta = block.timestamp`).
- La **oferta más alta inicial** es igual a la oferta base (`ofertaMasAlta = ofertaBase`).

📌 **Importante:** El constructor ejecuta estas acciones **automáticamente** cuando el contrato se despliega en la blockchain, asegurando las reglas antes de que la subasta comience.

---

## 🔑 Variables Principales  

- `subastaTerminada` (**bool**): Indica si la subasta ha finalizado.  
- `habilitarDevoluciones` (**bool**): Permite el retiro de fondos por oferentes no ganadores.  
- `ofertaBase` (**uint256**): Monto mínimo para ofertar (**1 Ether**).  
- `tiempoDuracionSubasta` (**uint256**): Duración total de la subasta (**3 días**).  
- `tiempoInicioSubasta` (**uint256**): Fecha en que el contrato fue creado.  
- `direccionOwner` (**address payable**): Dirección del **subastador**.  
- `ganadorDireccion` (**address**): Dirección del actual **ganador**.  
- `depositos` (**mapping**): Almacena los fondos depositados por cada oferente.  
- `ofertas` (**mapping**): Registra todas las ofertas realizadas por cada usuario.  
- `matriz_ofertas` (**array**): Guarda el historial de ofertas realizadas.  

---

## ⚙️ Modificadores  

Los modificadores aplican reglas antes de ejecutar ciertas funciones:  

- 🏷️ **`esMayorOferta(valor)`**: La oferta debe superar en **5%** la más alta actual.  
- 👑 **`isOwner()`**: Solo el dueño del contrato puede ejecutar ciertas funciones.  
- 🙅‍♂️ **`notOwner()`**: Impide que el dueño participe en la subasta.  
- ⏳ **`subastaTiempoFinalizado()`**: Asegura que la subasta haya terminado antes de devolver fondos.  
- 🚫 **`subastaNoTerminada()`**: Evita modificaciones en una subasta ya finalizada.  
- 💸 **`devolucionesHabilitadas()`**: Solo permite retirar fondos si el subastador lo activa.  
- 🚷 **`isNotGanador(direccion)`**: Asegura que el **ganador** no retire su depósito completo.  

---

## 🚀 Funcionalidades  

### 1️⃣ **Realizar una Oferta (`OFERTAR()`)** 💰  
Permite a los participantes ofertar enviando Ether.  

**Reglas:**  
✅ La oferta debe ser **mayor en 5%** a la más alta actual.  
✅ Se extiende el tiempo de la subasta en **10 minutos** si quedan al menos 10 min para finalizar.  
✅ Almacena los fondos **en el contrato (`address(this)`)**. Puedes verificar el monto con `verBalanceContrato()`.  
✅ Tambien se registra el valor en el deposito del oferente con `depositos[msg.sender]+= msg.value`.  

### 2️⃣ **Finalizar Subasta (`finalizarSubasta()`)** 🔚  
Solo el subastador puede finalizarla, habilitando el retiro de fondos.  

### 3️⃣ **Retorno de Depósitos (`retornarDeposito()`)** 💸  
Permite a los oferentes retirar sus depósitos **excepto** el ganador.  
📌 **Retención:** Se aplica un **2% de comisión**.  

### 4️⃣ **Retiro Parcial de Fondos (`retornarDepositoParciales()`)** 📉  
Los oferentes pueden retirar hasta el monto de su **última oferta**, aplicando el **2% de comisión**.  

---

## 📊 Funciones Auxiliares  
- `verBalanceContrato()` 🏦: Muestra el balance total del contrato.  
- `verGanador()` 🏆: Retorna la dirección del **ganador** y sus ofertas realizadas.  
- `verTodasLasOfertas()` 📜: Devuelve todas las ofertas registradas en la subasta.  
- `verTiempoFaltante()` ⏳: Calcula cuánto tiempo queda para que la subasta finalice.  
- `verDepositoOferente()` 💰: Muestra el depósito actual de un oferente.  

---

## ✅ Consideraciones de Seguridad  

🔒 Uso de **modificadores** para evitar **reentrancy attacks** y accesos indebidos.  
💡 Los depósitos son **reembolsables**, excepto para el **ganador**.  
⏱️ Se permite extender la subasta en caso de ofertas estratégicas.  

---

