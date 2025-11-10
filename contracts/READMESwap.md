# Utlizando el FakeUniSwap

## Creamos dos instancias del contrato BolivaresFuertesContract

<div align="center">
  <img src="..\img\BolivaresFuerte.png" alt="Deploy TestNet">
</div>

### Direcciones

* Contrato 1:	0x2E9d30761DB97706C536A112B9466433032b28e3
* Contrato 2:	0xf2B1114C644cBb3fF63Bf1dD284c8Cd716e95BE9

## Creamos la instancia del contrato FakeUniSwap

* Asignamos las direcciones anteriores como entrada para el despliegue del contrato y de ratio asignmos 4 para esta prueba

<div align="center">
  <img src="..\img\FakeUniSwap.png" alt="Deploy TestNet">
</div>

## Las instancias

* Instancias desplegadas

<div align="center">
  <img src="..\img\Instancias.png" alt="Deploy TestNet">
</div>

## Liquidez

* Inyectar Tokens B al contrato Swap

<div align="center">
  <img src="..\img\TransferirTokenB.png" alt="Deploy TestNet">
</div>

### Verificamos balance del Swap

<div align="center">
  <img src="..\img\BalanceSwap.png" alt="Deploy TestNet">
</div>

## Simulacion y transferencia eal

* Realizamos una simulación 

<div align="center">
  <img src="..\img\Simulacion.png" alt="Deploy TestNet">
</div>

## Aprobar

* Token A otorga 50 al gastador (Swap)

<div align="center">
  <img src="..\img\approve.png" alt="Deploy TestNet">
</div>

## Allowance

* El owner (Token A) autoriza al gastador (Swap) gastar los 50

<div align="center">
  <img src="..\img\allowance.png" alt="Deploy TestNet">
</div>

## Transferencia a una dirección que espera recibir

* Direccion que recibe 0x35C5b417169Ad9348d0eF91c2804e5781Cf04b18

<div align="center">
  <img src="..\img\transferencia.png" alt="Deploy TestNet">
</div>

## Validamos balance 

* Validamos que halla recibido los token de 0x35C5b417169Ad9348d0eF91c2804e5781Cf04b18

<div align="center">
  <img src="..\img\balanceTokenRecibidos.png" alt="Deploy TestNet">
</div>











