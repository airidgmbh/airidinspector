# airidinspector
Example application to use the AirID and send some APDUs

## Format of APDU test file:
- Optional line with
  T=0
  or
  T=1
  to select protocol in case of Dual-mode cards
- Optional line beginnig with ATR: to specifiy ATR of cards to be used
- After that: lines beginning with # are ignored, pairs of request/response hex
- if only SW1SW2 of response is given the response data is ignored
