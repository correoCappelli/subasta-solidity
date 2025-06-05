# Subasta Solidity - Auditoría 
- Prof . Sebastian Perez + ETHKIPU.ORG talento-tech T AM

## Introducción
Este contrato implementa una **subasta descentralizada** en Ethereum, permitiendo a los usuarios ofertar y competir por un activo dentro de un período determinado. Solo el dueño de la subasta puede finalizarla y habilitar la devolución de depósitos.
**Nota** : Si se quiere que `finalizarSubasta()` y `retornarDeposito()` estén habilitados unicamente al terminar la subasta, entonces, hay que descomentar el modifier `//subastaTiempoFinalizado` de las funciones.

## Características principales:
- **Recepción de Ether** mediante `receive()` y `fallback()`.
- **Registro de ofertas** y determinación del **ganador**.
- **Tiempo límite de la subasta** con posibilidad de extensión.
- **Protección contra ofertas fraudulentas** (debe superar la oferta más alta en un 5%).
- **Finalización y devoluciones** por parte del subastador.

---

## 📌 Variables Principales
| **Variable**             | **Descripción** |
|--------------------------|---------------|
| `subastaTerminada`       | Estado de la subasta (activa/finalizada). |
| `habilitarDevoluciones`  | Indica si los depósitos pueden devolverse. |
| `ofertaBase`            | Oferta mínima inicial (1 Ether). |
| `tiempoDuracionSubasta` | Duración máxima de la subasta. |
| `direccionSubasta`      | Dirección del dueño de la subasta. |
| `ganadorDireccion`      | Dirección del actual ganador de la subasta. |
| `ofertaMasAlta`         | Oferta más alta hasta el momento. |

---

## ⚡ Funcionalidades y Explicación de Funciones Principales

### `OFERTAR()`
📌 **Función para ofertar** en la subasta. Solo permite ofertas mayores a la actual oferta más alta +5%.  
✅ Si el tiempo de subasta finaliza, **emite un evento** declarando el ganador.  
✅ Si se realiza una oferta válida:
   - Se envía Ether a la dirección del subastador.
   - Se almacena la oferta y el oferente en un **mapping**.
   - Se actualiza el ganador y el tiempo restante **(se extiende 10 minutos si faltan más de 10 minutos)**.

---

### `finalizarSubasta()`
📌 Permite **finalizar la subasta** solo si el dueño del contrato la ejecuta.  
✅ Establece `subastaTerminada = true` y **habilita las devoluciones** (`habilitarDevoluciones = true`).

---

### `retornarDeposito(address payable dir)`
📌 **Devuelve depósitos** a los oferentes que no ganaron la subasta, reteniendo un **2% de comisión**.  
✅ Solo ejecutable por el dueño del contrato.  
✅ Requiere que `habilitarDevoluciones = true`.  
✅ Usa `call{value: (msg.value * 98) / 100}` para procesar el retiro.
✅ El subastador o owner tiene que ingresar el monto del deposito a retornar en msg.value.

---

### `retornarDepositosParciales(address payable dir)`
📌 **Devuelve depósitos parciales** a los oferentes aún si la subasta no finalizó, reteniendo un **2% de comisión**.  
✅ Solo ejecutable por el dueño del contrato.  
✅ NO eequiere que `habilitarDevoluciones = true`. Ya que está habilitada con la subasta en curso  
✅ Usa `call{value: (msg.value * 98) / 100}` para procesar el retiro.
✅ El subastador o owner tiene que ingresar el monto del deposito a retornar en msg.value.
✅ En el deposito tiene que remaner siempre el monto correspondiente a la última oferta (más alta del oferente).

---


### `verGanador()`
📌 Devuelve la **lista de ofertas** realizadas por el ganador y su dirección.

---

### `verTodasLasOfertas()`
📌 Devuelve todas las ofertas realizadas por los usuarios en la subasta.

---

### `verDepositoOferente()`
📌 Permite a un **usuario ver cuánto tiene depositado** en el contrato.

---

## 🎯 Modificadores de Función
| **Modificador** | **Funcionalidad** |
|----------------|-----------------|
| `esMayorOferta(valor)` | Requiere que la oferta supere en 5% la oferta más alta. |
| `isOwner()` | Solo el dueño del contrato puede ejecutar la función. |
| `notOwner()` | Solo participantes pueden ofertar (el dueño no puede). |
| `subastaNoTerminada()` | Se ejecuta solo si la subasta sigue activa. |
| `devolucionesHabilitadas()` | Solo permite devoluciones si el dueño las habilita. |
| `isNotGanador(direccion)` | Evita que el ganador retire su depósito. |

---

## 🔥 Eventos en el Contrato
| **Evento** | **Descripción** |
|-----------|--------------|
| `NuevaOferta(valor, ofertante)` | Se emite al realizar una nueva oferta. |
| `SubastaFinalizada(ganador, ofertaGanadora)` | Se emite cuando la subasta finaliza. |
| `VerOfertantes(ofertante, ofertas)` | Se emite al consultar ofertas de un usuario. |

---

## ⏳ Funciones Auxiliares
- `verTiempoFaltante()`: Muestra el **tiempo restante** antes de finalizar la subasta.
- `verTimestampActual()`: Retorna el **timestamp actual** en segundos.
- `getOfertaMasALtaOferente(oferente)`: Obtiene la oferta más alta de un usuario.
- `verOfertasOferenteActual()`: Retorna todas las ofertas realizadas por el **usuario llamante**.

---

## 🛠 Auditoría y Seguridad
✅ **Protección contra ofertas inválidas** (`modifier esMayorOferta`).  
✅ **Restricción de accesos** (`modifier isOwner, notOwner`).  
✅ **Gestión de depósitos segura** con transferencias `call{value: msg.value}`.  
✅ **Evita bloqueos** extendiendo automáticamente la subasta si hay competencia.

---

## 🚀 Conclusión
Este contrato de subasta en Solidity proporciona un mecanismo seguro y transparente para ofertar, asegurando una competencia justa entre participantes. Todas las funcionalidades han sido diseñadas para proteger fondos, establecer reglas claras y permitir auditorías eficientes. ⚡

