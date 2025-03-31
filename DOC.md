# Documentação do Código: huffmannode.prg

Este documento descreve a implementação da classe `HuffmanNode` no arquivo `huffmannode.prg`, parte do projeto [naldodj-hb-huffman](https://github.com/naldodj/naldodj-hb-huffman). O código está disponível em [src/core/huffmannode.prg](https://github.com/naldodj/naldodj-hb-huffman/blob/main/src/core/huffmannode.prg) e foi projetado para estudo do algoritmo de Huffman em Harbour, com otimizações em C.

## Visão Geral

O arquivo `huffmannode.prg` implementa uma classe orientada a objetos para compressão e descompressão de textos usando o algoritmo de Huffman. Ele inclui métodos para construir a árvore de Huffman, gerar códigos binários, empacotar bits e reconstruir o texto original, além de funções em C para melhorar o desempenho.

### Cabeçalho
```harbour
/*
 _              __   __                                             _
| |__   _   _  / _| / _| _ __ ___    __ _  _ __   _ __    ___    __| |  ___
| '_ \ | | | || |_ | |_ | '_ ` _ \  / _` || '_ \ | '_ \  / _ \  / _` | / _ \
| | | || |_| ||  _||  _|| | | | | || (_| || | | || | | || (_) || (_| ||  __/
|_| |_| \__,_||_|  |_|  |_| |_| |_| \__,_||_| |_||_| |_| \___/  \__,_| \___|

 hb HuffmanNode

 Released to Public Domain.
 --------------------------------------------------------------------------------------
*/
```

- **Licença**: Domínio Público, permitindo uso e modificação livres.

## Estrutura da Classe

### Declaração
```harbour
#include "hbclass.ch"

REQUEST HB_CODEPAGE_UTF8EX

class HuffmanNode
   data oHuffmanTree as object
   data hHuffmanMap as hash
   data cChar as character
   data nFreq as numeric
   data oLeft as object
   data oRight as object

   method isLeaf() as logical
   method BuildHuffmanMap(oNode as object, cCode as character)
   method BuildHuffmanTree(cText as character, hFreq as hash) as object
   method RebuildHuffmanTree(hMap as hash) as object
   method PackBitsToIntegers(cBits as character, nBitLen as numeric) as array
   method UnpackBitsFromIntegers(aPacked as array) as character
   method New(cChar as character, nFreq as numeric, oLeft as object, oRight as object) CONSTRUCTOR
   method HuffmanCompress(cText as character) as hash
   method HuffmanDecompress(hCompressed as hash) as character
end class
```

- **Dependências**: Requer `HB_CODEPAGE_UTF8EX` para suporte a UTF-8.

#### Dados
| Nome            | Tipo      | Descrição                                      |
|-----------------|-----------|------------------------------------------------|
| `oHuffmanTree`  | Object    | Árvore de Huffman construída ou reconstruída.  |
| `hHuffmanMap`   | Hash      | Mapa de códigos binários para cada caractere.  |
| `cChar`         | Character | Caractere armazenado em um nó da árvore.       |
| `nFreq`         | Numeric   | Frequência de ocorrência do caractere.         |
| `oLeft`         | Object    | Filho esquerdo do nó na árvore (0).            |
| `oRight`        | Object    | Filho direito do nó na árvore (1).             |

#### Métodos
| Nome                     | Retorno    | Parâmetros                                      | Descrição                                           |
|--------------------------|------------|------------------------------------------------|-----------------------------------------------------|
| `New`                    | Object     | `cChar`, `nFreq`, `oLeft`, `oRight`            | Construtor do nó.                                   |
| `isLeaf`                 | Logical    | -                                              | Verifica se o nó é uma folha.                       |
| `BuildHuffmanMap`        | -          | `oNode`, `cCode`                               | Gera o mapa de códigos binários.                    |
| `BuildHuffmanTree`       | Object     | `cText`, `hFreq` (opcional)                    | Constrói a árvore de Huffman.                       |
| `RebuildHuffmanTree`     | Object     | `hMap`                                         | Reconstrói a árvore a partir de um mapa.            |
| `PackBitsToIntegers`     | Array      | `cBits`, `nBitLen`                             | Empacota bits em inteiros de 64 bits.               |
| `UnpackBitsFromIntegers` | Character  | `aPacked`                                      | Desempacota inteiros em uma string binária.         |
| `HuffmanCompress`        | Hash       | `cText`                                        | Comprime o texto em um hash.                        |
| `HuffmanDecompress`      | Character  | `hCompressed`                                  | Descomprime o texto a partir de um hash.            |

---

## Métodos Detalhados

### `New`
```harbour
method New(cChar as character, nFreq as numeric, oLeft as object, oRight as object) class HuffmanNode
   hb_default(@cChar, "")
   hb_default(@nFreq, 0)
   ::hHuffmanMap := {=>}
   ::cChar := cChar
   ::nFreq := nFreq
   ::oLeft := oLeft
   ::oRight := oRight
   return self as object
```
- **Descrição**: Constrói um novo nó da árvore de Huffman com valores padrão para `cChar` (vazio) e `nFreq` (0).
- **Uso**: Base para criar nós folha ou intermediários.

### `isLeaf`
```harbour
method isLeaf() class HuffmanNode
   return ((::oLeft == nil) .and. (::oRight == nil)) as logical
```
- **Descrição**: Retorna `.T.` se o nó não tiver filhos, indicando que é uma folha.

### `BuildHuffmanTree`
```harbour
method BuildHuffmanTree(cText as character, hFreq as hash) class HuffmanNode
   local aNodes as array := {}
   local cChar as character
   local cRemainingText as character
   local oNode as object
   local oLeft as object
   local oRight as object

   self:oHuffmanTree := HuffmanNode():New("", 0, nil, nil)
   self:hHuffmanMap := {=>}

   if (HB_ISHash(hFreq))
   else
      hFreq := {=>}
      cRemainingText := cText
      while (hb_BLen(cRemainingText) > 0)
         cChar := hb_BSubStr(cRemainingText, 1, 1)
         hFreq[cChar] := StrOccurs(cChar, @cRemainingText)
      end while
   endif

   for each cChar in hb_HKeys(hFreq)
      aAdd(aNodes, HuffmanNode():New(cChar, hFreq[cChar], nil, nil))
   next each

   if (Len(aNodes) == 0)
      return nil
   elseif (Len(aNodes) == 1)
      return aNodes[1]
   endif

   while (Len(aNodes) > 1)
      aNodes := aSort(aNodes, {|x, y| x:nFreq < y:nFreq})
      oLeft := aNodes[1]
      hb_ADel(aNodes, 1, .T.)
      oRight := aNodes[1]
      hb_ADel(aNodes, 1, .T.)
      oNode := HuffmanNode():New(nil, oLeft:nFreq + oRight:nFreq, oLeft, oRight)
      aAdd(aNodes, oNode)
   end while

   return aNodes[1] as object
```
- **Descrição**: Constrói a árvore de Huffman a partir de um texto ou de um hash de frequências pré-calculado.
- **Parâmetros**:
  - `cText`: Texto original (opcional se `hFreq` for fornecido).
  - `hFreq`: Hash com frequências (opcional).
- **Notas**: Usa `StrOccurs` para contar e remover caracteres dinamicamente.

### `BuildHuffmanMap`
```harbour
method BuildHuffmanMap(oNode as object, cCode as character) class HuffmanNode
   local aStack as array := {{oNode, cCode}}
   local oCurrent as object
   local cCurrentCode as character

   while (Len(aStack) > 0)
      oCurrent := aStack[Len(aStack)][1]
      cCurrentCode := aStack[Len(aStack)][2]
      hb_ADel(aStack, Len(aStack), .T.)

      if (oCurrent:isLeaf())
         self:hHuffmanMap[oCurrent:cChar] := cCurrentCode
      else
         if (oCurrent:oRight != nil)
            aAdd(aStack, {oCurrent:oRight, cCurrentCode + "1"})
         endif
         if (oCurrent:oLeft != nil)
            aAdd(aStack, {oCurrent:oLeft, cCurrentCode + "0"})
         endif
      endif
   end while
   return
```
- **Descrição**: Gera o mapa de códigos binários iterativamente usando uma pilha.
- **Parâmetros**:
  - `oNode`: Nó raiz da árvore.
  - `cCode`: Código binário inicial (geralmente "").

### `HuffmanCompress`
```harbour
method HuffmanCompress(cText as character) class HuffmanNode
   local aPacked as array
   local cEncoded as character := ""
   local hFreq as hash := {=>}
   local cRemainingText as character := cText
   local i as numeric
   local nBitLen as numeric

   self:oHuffmanTree := self:BuildHuffmanTree(cText)
   if (self:oHuffmanTree == nil)
      return {=>} as hash
   endif

   while (hb_BLen(cRemainingText) > 0)
      cChar := hb_BSubStr(cRemainingText, 1, 1)
      hFreq[cChar] := StrOccurs(cChar, @cRemainingText)
   end while

   self:BuildHuffmanMap(self:oHuffmanTree, "")
   for i := 1 to hb_BLen(cText)
      cEncoded += self:hHuffmanMap[hb_BSubStr(cText, i, 1)]
   next i

   nBitLen := hb_BLen(cEncoded)
   aPacked := self:PackBitsToIntegers(cEncoded, nBitLen)
   
   return {"freq" => hFreq, "data" => aPacked} as hash
```
- **Descrição**: Comprime o texto em um hash contendo frequências e dados empacotados.
- **Retorno**: Hash com `"freq"` (frequências) e `"data"` (bits empacotados).

### `HuffmanDecompress`
```harbour
method HuffmanDecompress(hCompressed as hash) class HuffmanNode
   local cBit as character
   local cEncoded as character
   local cDecoded as character := ""
   local hFreq as hash
   local i as numeric
   local nBitLen as numeric
   local oNode as object
   local oRoot as object

   begin sequence
      if (!(hb_hHasKey(hCompressed, "freq") .and. hb_hHasKey(hCompressed, "data")))
         break
      endif

      hFreq := hCompressed["freq"]
      if (!HB_ISHash(hFreq)) .or. (Len(hCompressed["data"]) < 1)
         break
      endif

      cEncoded := self:UnpackBitsFromIntegers(hCompressed["data"])
      self:oHuffmanTree := self:BuildHuffmanTree(nil, hFreq)
      self:hHuffmanMap := {=>}
      self:BuildHuffmanMap(self:oHuffmanTree, "")
      oRoot := self:oHuffmanTree
      if (oRoot == nil)
         break
      endif

      nBitLen := hCompressed["data"][1]
      oNode := oRoot

      for i := 1 to nBitLen
         cBit := hb_BSubStr(cEncoded, i, 1)
         oNode := if(cBit == "0", oNode:oLeft, oNode:oRight)
         if (oNode == nil)
            exit
         endif
         if (oNode:isLeaf())
            cDecoded += oNode:cChar
            oNode := oRoot
         endif
      next i
   end sequence

   return cDecoded as character
```
- **Descrição**: Descomprime o texto a partir de um hash comprimido.
- **Parâmetros**:
  - `hCompressed`: Hash com `"freq"` e `"data"`.

### `PackBitsToIntegers`
```harbour
method PackBitsToIntegers(cBits as character, nBitLen as numeric) class HuffmanNode
   return PackBitsToIntegers(cBits, nBitLen)
```
- **Descrição**: Chama a função em C para empacotar bits em inteiros.

### `UnpackBitsFromIntegers`
```harbour
method UnpackBitsFromIntegers(aPacked as array) class HuffmanNode
   local cBits as character := ""
   local i as numeric
   local j as numeric
   local nBuffer as numeric

   for i := 2 to Len(aPacked)
      nBuffer := aPacked[i]
      for j := 63 to 0 step -1
         cBits += if(hb_bitTest(nBuffer, j), "1", "0")
      next j
   next i

   return cBits
```
- **Descrição**: Converte um array de inteiros em uma string binária.

### `RebuildHuffmanTree`
```harbour
method RebuildHuffmanTree(hMap as hash) class HuffmanNode
   local cBit as character
   local cChar as character
   local cCode as character
   local i as numeric
   local oRoot as object := HuffmanNode():New(nil, 0, nil, nil)
   local oNode as object

   for each cChar in hb_HKeys(hMap)
      cCode := hMap[cChar]
      oNode := oRoot
      for i := 1 to hb_BLen(cCode)
         cBit := hb_BSubStr(cCode, i, 1)
         if (cBit == "0")
            if (oNode:oLeft == nil)
               oNode:oLeft := HuffmanNode():New(nil, 0, nil, nil)
            endif
            oNode := oNode:oLeft
         else
            if (oNode:oRight == nil)
               oNode:oRight := HuffmanNode():New(nil, 0, nil, nil)
            endif
            oNode := oNode:oRight
         endif
      next i
      oNode:cChar := cChar
   next each

   return oRoot as object
```
- **Descrição**: Reconstrói a árvore a partir de um mapa de códigos.

---

## Funções em C

### `CTON`
```c
HB_FUNC_STATIC(CTON)
{
   const char *szNumber = hb_parc(1);
   int iLen = hb_parclen(1);
   if (szNumber && iLen > 0)
   {
      HB_MAXUINT nValue = 0;
      for (int i = 0; i < iLen; i++)
         nValue = (nValue << 8) | (HB_UCHAR)szNumber[i];
      hb_retnint(nValue);
   }
   else
      hb_retni(0);
}
```
- **Descrição**: Converte uma string de bytes em um inteiro.

### `NTOC`
```c
HB_FUNC_STATIC(NTOC)
{
   HB_MAXUINT nValue = hb_parnint(1);
   char szBuffer[16];
   int i = sizeof(szBuffer);
   do
   {
      szBuffer[--i] = (char)(nValue & 0xFF);
      nValue >>= 8;
   } while (nValue != 0 && i > 0);
   hb_retclen(&szBuffer[i], sizeof(szBuffer) - i);
}
```
- **Descrição**: Converte um inteiro em uma string compacta (base 256).

### `STROCCURS`
```c
HB_FUNC_STATIC(STROCCURS)
{
   if (HB_ISCHAR(1) && HB_ISCHAR(2) && HB_ISBYREF(2))
   {
      const char *s1 = hb_parc(1);
      char *s2 = hb_itemGetC(hb_param(2, HB_IT_STRING));
      HB_ISIZ len = hb_parclen(2);
      HB_ISIZ count = 0;
      HB_ISIZ newLen = 0;

      for (HB_ISIZ i = 0; i < len; i++)
      {
         if (s1[0] == s2[i])
            count++;
         else
            s2[newLen++] = s2[i];
      }

      hb_storclen(s2, newLen, 2);
      hb_xfree(s2);
      hb_retns(count);
   }
   else
      hb_retns(0);
}
```
- **Descrição**: Conta ocorrências de um caractere e remove-as do texto por referência.

### `PACKBITSTOINTEGERS`
```c
HB_FUNC_STATIC(PACKBITSTOINTEGERS)
{
   if (HB_ISCHAR(1) && HB_ISNUM(2))
   {
      const char *cBits = hb_parc(1);
      HB_ISIZ nBitLen = hb_parnl(2);
      HB_ISIZ i, bufferLen = 0;
      HB_MAXUINT buffer = 0;
      PHB_ITEM aOut = hb_itemArrayNew((nBitLen + 63) / 64 + 1);

      hb_arraySetNL(aOut, 1, nBitLen);

      for (i = 0; i < nBitLen; i++)
      {
         buffer = (buffer << 1) | (cBits[i] == '1' ? 1 : 0);
         if (++bufferLen >= 64)
         {
            hb_arraySetNInt(aOut, (i / 64) + 2, buffer);
            buffer = 0;
            bufferLen = 0;
         }
      }

      if (bufferLen > 0)
         hb_arraySetNInt(aOut, (nBitLen / 64) + 2, buffer << (64 - bufferLen));

      hb_itemReturnRelease(aOut);
   }
   else
      hb_ret();
}
```
- **Descrição**: Empacota uma string binária em um array de inteiros.

---

## Exemplo de Uso
```harbour
#include "huffmannode.prg"

procedure Main()
   local oHuffman := HuffmanNode():New()
   local cTexto := "AABBC"
   local hCompressed := oHuffman:HuffmanCompress(cTexto)
   local cDecompressed := oHuffman:HuffmanDecompress(hCompressed)

   ? "Original:", cTexto
   ? "Compressed:", hb_JSONEncode(hCompressed)
   ? "Decompressed:", cDecompressed
return
```

---

## Notas
- **Otimização**: Funções em C como `STROCCURS` e `PACKBITSTOINTEGERS` aumentam o desempenho.
- **Flexibilidade**: Suporta construção da árvore com texto ou frequências pré-calculadas.

Esta documentação reflete a versão atual do código em [huffmannode.prg](https://github.com/naldodj/naldodj-hb-huffman/blob/main/src/core/huffmannode.prg). Para dúvidas ou contribuições, visite o repositório!

---
