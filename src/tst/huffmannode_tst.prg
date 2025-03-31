/*
 _              __   __                                             _           _         _
| |__   _   _  / _| / _| _ __ ___    __ _  _ __   _ __    ___    __| |  ___    | |_  ___ | |_
| '_ \ | | | || |_ | |_ | '_ ` _ \  / _` || '_ \ | '_ \  / _ \  / _` | / _ \   | __|/ __|| __|
| | | || |_| ||  _||  _|| | | | | || (_| || | | || | | || (_) || (_| ||  __/   | |_ \__ \| |_
|_| |_| \__,_||_|  |_|  |_| |_| |_| \__,_||_| |_||_| |_| \___/  \__,_| \___|    \__||___/ \__|

 Example usage with valid and invalid test cases.

 Released to Public Domain.
 --------------------------------------------------------------------------------------

*/

REQUEST HB_CODEPAGE_UTF8EX

// Example usage
procedure Main()
   local cCDP as character:=hb_cdpSelect("UTF8EX")

   CLS

   hbHuffmanTST()

   hb_cdpSelect(cCDP)

   return

static procedure hbHuffmanTST()

   local cText as character
   local cCompressed as character
   local cDecompressed as character

   local hCompressed as hash

   local oHuffmanNode as object:=HuffmanNode():New()

   #pragma __cstream|cText:=%s
Marinaldo de Jesus
   #pragma __endtext

   hCompressed:=oHuffmanNode:HuffmanCompress(cText)
   cCompressed:=hb_JSONEncode(hCompressed)
   cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)

   ? "Original: ",cText
   ? "Compressed: ",cCompressed,hb_eol()
   ? "Decompressed: ",cDecompressed,hb_eol()
   ? "Matching: ",(cDecompressed==cText),hb_eol(),hb_eol()

   ? Replicate("=",80),hb_eol()

   #pragma __cstream|cText:=%s
THIS TEXT VERY,VERY,VERY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY LARGE WILL PASS THROUGH THE HUFFMAN FILTER!
   #pragma __endtext

   hCompressed:=oHuffmanNode:HuffmanCompress(cText)
   cCompressed:=hb_JSONEncode(hCompressed)
   cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)

   ? "Original: ",cText
   ? "Compressed: ",cCompressed,hb_eol()
   ? "Decompressed: ",cDecompressed,hb_eol()
   ? "Matching: ",(cDecompressed==cText),hb_eol(),hb_eol()

   ? Replicate("=",80),hb_eol()

   if (hb_FileExists("./data/loremipsum.txt"))

      cText:=hb_MemoRead("./data/loremipsum.txt")

      hCompressed:=oHuffmanNode:HuffmanCompress(cText)
      cCompressed:=hb_JSONEncode(hCompressed)
      cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)

      ? "Original: ",cText
      ? "Compressed: ",cCompressed,hb_eol()
      ? "Decompressed: ",cDecompressed,hb_eol()
      ? "Matching: ",(cDecompressed==cText),hb_eol(),hb_eol()

   endif

   return

#include "huffmannode.prg"
