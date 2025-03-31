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

#include "hbclass.ch"

REQUEST HB_CODEPAGE_UTF8EX

class HuffmanNode

   data cChar as character
   data nFreq as numeric

   data hHuffmanMap as hash

   data oLeft as object
   data oRight as object
   data oHuffmanTree as object

   method isLeaf() as logical
   method BuildHuffmanMap(oNode as object,cCode as character)
   method BuildHuffmanTree(cText as character,hFreq as hash) as object
   method RebuildHuffmanTree(hMap as hash) as object
   method PackBitsToIntegers(cBits as character,nBitLen as numeric) as array
   method UnpackBitsFromIntegers(aPacked as array) as character
   method New(cChar as character,nFreq as numeric,oLeft as object,oRight as object) CONSTRUCTOR
   method HuffmanCompress(cText as character) as hash
   method HuffmanDecompress(hCompressed as hash) as character

end class

method New(cChar as character,nFreq as numeric,oLeft as object,oRight as object) class HuffmanNode
   hb_default(@cChar,"")
   hb_default(@nFreq,0)
   self:hHuffmanMap:={=>}
   self:cChar:=cChar
   self:nFreq:=nFreq
   self:oLeft:=oLeft
   self:oRight:=oRight
   return(self) as object

method isLeaf() class HuffmanNode
   return(((self:oLeft==nil).and.(self:oRight==nil))) as logical

method BuildHuffmanTree(cText as character,hFreq as hash) class HuffmanNode

   local aNodes as array:={}

   local cChar as character
   local cRemainingText as character

   local oNode as object
   local oLeft as object
   local oRight as object

   self:oHuffmanTree:=HuffmanNode():New("",0,nil,nil)
   self:hHuffmanMap:={=>}

   if (!HB_ISHash(hFreq).or.Empty(hFreq))
      hFreq:={=>}
      cRemainingText:=cText
      while (hb_BLen(cRemainingText)>0)
         cChar:=hb_BSubStr(cRemainingText,1,1)
         hFreq[cChar]:=StrOccurs(cChar,@cRemainingText)
      end while
   endif

   // Criar nós iniciais a partir de hFreq
   for each cChar in hb_HKeys(hFreq)
      aAdd(aNodes,HuffmanNode():New(cChar,hFreq[cChar],nil,nil))
   next each

   if (Len(aNodes)==0)
      return(nil)
   elseif (Len(aNodes)==1)
      return(aNodes[1]) as object
   endif

   while (Len(aNodes) > 1)
      aNodes:=aSort(aNodes,{|x,y| x:nFreq < y:nFreq})
      oLeft:=aNodes[1]
      hb_aDel(aNodes,1,.T.)
      oRight:=aNodes[1]
      hb_aDel(aNodes,1,.T.)
      oNode:=HuffmanNode():New(nil,oLeft:nFreq + oRight:nFreq,oLeft,oRight)
      aAdd(aNodes,oNode)
   end while

   return(aNodes[1]) as object

method procedure BuildHuffmanMap(oNode as object,cCode as character) class HuffmanNode

   local aStack as array:={{oNode,cCode}}

   local cCurrentCode as character

   local oCurrent as object

   while (Len(aStack)>0)

      oCurrent:=aStack[Len(aStack)][1]
      cCurrentCode:=aStack[Len(aStack)][2]
      hb_aDel(aStack,Len(aStack),.T.)

      if (oCurrent:isLeaf())
         self:hHuffmanMap[oCurrent:cChar]:=cCurrentCode
      else
         if (oCurrent:oRight!=nil)
            aAdd(aStack,{oCurrent:oRight,cCurrentCode+"1"})
         endif
         if (oCurrent:oLeft!=nil)
            aAdd(aStack,{oCurrent:oLeft,cCurrentCode+"0"})
         endif
      endif
   end while

   return

method HuffmanCompress(cText as character) class HuffmanNode

   local aPacked as array

   local cChar as character
   local cEncoded as character:=""
   local cRemainingText as character:=cText

   local hFreq as hash:={=>}

   local i as numeric
   local nBitLen as numeric

   self:oHuffmanTree:=self:BuildHuffmanTree(cText)  // Calcula hFreq internamente
   if (self:oHuffmanTree==nil)
      return({=>}) as hash
   endif

   // Copiar hFreq do processo de BuildHuffmanTree
   while (hb_BLen(cRemainingText) > 0)
      cChar:=hb_BSubStr(cRemainingText,1,1)
      hFreq[cChar]:=StrOccurs(cChar,@cRemainingText)
   end while

   self:BuildHuffmanMap(self:oHuffmanTree,"")
   for i:=1 to hb_BLen(cText)
      cEncoded+=self:hHuffmanMap[hb_BSubStr(cText,i,1)]
   next i

   nBitLen:=hb_BLen(cEncoded)
   aPacked:=self:PackBitsToIntegers(cEncoded,nBitLen)

   return({"freq" => hFreq,"data" => aPacked}) as hash

method RebuildHuffmanTree(hMap as hash) class HuffmanNode

   local cBit as character
   local cChar as character
   local cCode as character

   local i as numeric

   local oRoot as object:=HuffmanNode():New(nil,0,nil,nil)
   local oNode as object

   for each cChar in hb_HKeys(hMap)
      cCode:=hMap[cChar]
      oNode:=oRoot
      for i:=1 to hb_BLen(cCode)
         cBit:=hb_BSubStr(cCode,i,1)
         if (cBit=="0")
            if (oNode:oLeft==nil)
               oNode:oLeft:=HuffmanNode():New(nil,0,nil,nil)
            endif
            oNode:=oNode:oLeft
         else
            if (oNode:oRight==nil)
               oNode:oRight:=HuffmanNode():New(nil,0,nil,nil)
            endif
            oNode:=oNode:oRight
         endif
      next i
      oNode:cChar:=cChar
   next each

   return(oRoot) as object

method HuffmanDecompress(hCompressed as hash) class HuffmanNode
   local cBit as character
   local cEncoded as character
   local cDecoded as character:=""
   local hFreq as hash
   local i as numeric
   local nBitLen as numeric
   local oNode as object
   local oRoot as object

   begin sequence
      if (!(hb_hHasKey(hCompressed,"freq") .and. hb_hHasKey(hCompressed,"data")))
         break
      endif

      hFreq:=hCompressed["freq"]
      if ((!HB_ISHash(hFreq)).or.(Len(hCompressed["data"])<1))
         break
      endif

      cEncoded:=self:UnpackBitsFromIntegers(hCompressed["data"])
      self:oHuffmanTree:=self:BuildHuffmanTree(nil,@hFreq)  // Usa hFreq diretamente
      self:hHuffmanMap:={=>}
      self:BuildHuffmanMap(self:oHuffmanTree,"")
      oRoot:=self:oHuffmanTree
      if (oRoot==nil)
         break
      endif

      nBitLen:=hCompressed["data"][1]
      oNode:=oRoot

      for i:=1 to nBitLen
         cBit:=hb_BSubStr(cEncoded,i,1)
         oNode:=if(cBit=="0",oNode:oLeft,oNode:oRight)
         if (oNode==nil)
            exit
         endif
         if (oNode:isLeaf())
            cDecoded+=oNode:cChar
            oNode:=oRoot
         endif
      next i
   end sequence

   return(cDecoded) as character

method PackBitsToIntegers(cBits as character,nBitLen as numeric) class HuffmanNode
   // Chama função em C
   return(PackBitsToIntegers(cBits,nBitLen)) as array

method UnpackBitsFromIntegers(aPacked as array) class HuffmanNode

   local cBits as character:=""

   local i as numeric
   local j as numeric

   local nBuffer as numeric

   for i:=2 to Len(aPacked)
      nBuffer:=aPacked[i]
      for j:=63 to 0 step -1
         cBits+=if(hb_bitTest(nBuffer,j),"1","0")
      next j
   next i

   return(cBits) as character

#pragma BEGINDUMP

   #include "ct.h"
   #include "hbapi.h"

   HB_FUNC_STATIC(STROCCURS)
   {
      if (HB_ISCHAR(1) && HB_ISCHAR(2) && HB_ISBYREF(2))
      {
         const char *s1 = hb_parc(1);
         char *s2 = hb_itemGetC(hb_param(2,HB_IT_STRING));
         HB_ISIZ len = hb_parclen(2);
         HB_ISIZ count = 0;
         HB_ISIZ newLen = 0;

         for (HB_ISIZ i = 0; i < len; i++)
         {
            if (s1[0]==s2[i])
               count++;
            else
               s2[newLen++] = s2[i];
         }

         hb_storclen(s2,newLen,2);
         hb_xfree(s2);
         hb_retns(count);
      }
      else
         hb_retns(0);
   }

   HB_FUNC_STATIC(PACKBITSTOINTEGERS)
   {
      if (HB_ISCHAR(1) && HB_ISNUM(2))
      {
         const char *cBits = hb_parc(1);
         HB_ISIZ nBitLen = hb_parnl(2);
         HB_ISIZ i,bufferLen = 0;
         HB_MAXUINT buffer = 0;
         PHB_ITEM aOut = hb_itemArrayNew((nBitLen+63) / 64+1);

         hb_arraySetNL(aOut,1,nBitLen);

         for (i = 0; i < nBitLen; i++)
         {
            buffer = (buffer << 1) | (cBits[i]=='1' ? 1 : 0);
            if (++bufferLen >= 64)
            {
               hb_arraySetNInt(aOut,(i / 64)+2,buffer);
               buffer = 0;
               bufferLen = 0;
            }
         }

         if (bufferLen>0)
            hb_arraySetNInt(aOut,(nBitLen / 64)+2,buffer << (64 - bufferLen));

         hb_itemReturnRelease(aOut);
      }
      else
         hb_ret();
   }
#pragma ENDDUMP
