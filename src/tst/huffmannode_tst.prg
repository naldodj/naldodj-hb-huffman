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

   local cCDP as character

   #ifdef __ALT_D__    // Compile with -b -D__ALT_D__
     AltD(1)         // Enables the debugger. Press F5 to continue.
     AltD()          // Invokes the debugger
   #endif

   cCDP:=hb_cdpSelect("UTF8EX")

   CLS

   hbHuffmanTST()

   hb_cdpSelect(cCDP)

   return

static procedure hbHuffmanTST()

   local aColors as array
   local aFunTst as array

   local cText as character
   local cFunName as character
   local cCompressed as character
   local cDecompressed as character

   local hCompressed as hash

   local lMatch as logical

   local oHuffmanNode as object:=HuffmanNode():New()

   local i as numeric

   aFunTst:=Array(0)
   aAdd(aFunTst,{@hbHuffmanTST_01(),"hbHuffmanTST_01",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_02(),"hbHuffmanTST_02",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_03(),"hbHuffmanTST_03",.T.})
   aAdd(aFunTst,{@hbHuffmanTST_04(),"hbHuffmanTST_04",.T.})

   aColors:=getColors(Len(aFunTst))

   for i:=1 to Len(aFunTst)

      cText:=aFunTst[i][1]:Eval()
      cFunName:=aFunTst[i][2]

      SetColor(aColors[i])
      QOut("=== Test "+hb_NToC(i)+" ("+cFunName+"): ===",hb_eol())
      SetColor("") /* Reset color to default */

      hCompressed:=oHuffmanNode:HuffmanCompress(cText)
      cCompressed:=hb_JSONEncode(hCompressed)
      cDecompressed:=oHuffmanNode:HuffmanDecompress(hCompressed)

      ? "Original: ",cText
      ? "Compressed: ",cCompressed,hb_eol()
      ? "Decompressed: ",cDecompressed,hb_eol()

      lMatch:=(cDecompressed==cText)

      if (lMatch)
          SetColor("g+/n")
      else
          SetColor("r+/n")
      endif

      ? "Matching: ",(cDecompressed==cText),hb_eol(),hb_eol()

      SetColor("")

      ? Replicate("=",80),hb_eol()

   next i

   return

static function getColors(nTests as numeric)

    local aColors as array:=Array(nTests)
    local aColorBase as array:={"N","B","G","BG","R","RB","GR","W"}

    local i as numeric

    for i:=1 to nTests
        aColors[i]:="W+/"+aColorBase[(i-1)%8+1]
    next i

    return(aColors)

static function hbHuffmanTST_01()

    local cText as character

    #pragma __cstream|cText:=%s
Marinaldo de Jesus
    #pragma __endtext

    return(cText)

    static function hbHuffmanTST_02()

    local cText as character

    #pragma __cstream|cText:=%s
THIS TEXT VERY,VERY,VERY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY,VERY,EXTREMELY LARGE WILL PASS THROUGH THE HUFFMAN FILTER!
    #pragma __endtext

    return(cText)

    static function hbHuffmanTST_03()

    local cText as character

    if (hb_FileExists("./data/loremipsum.txt"))
        cText:=hb_MemoRead("./data/loremipsum.txt")
    else
        cText:=ProcName()
    endif

    return(cText)

    static function hbHuffmanTST_04()

    local cText as character

    if (hb_FileExists("./huffmannode.prg"))
        cText:=hb_MemoRead("./huffmannode.prg")
    else
        cText:=ProcName()
    endif

    return(cText)
