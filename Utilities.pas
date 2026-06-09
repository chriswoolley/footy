(*
-------------------------------------------------------------------------------
References :
-------------------------------------------------------------------------------
Purpose : General purpose utilities
-------------------------------------------------------------------------------
*)
unit Utilities;

interface

uses
  Windows, Classes, SysUtils;
  
function TrimTo(AStr : String; ALen : Integer) : String;
procedure Nop;

procedure StringToStream(AStream : TStream; AStr : String);
function StringFromStream(AStream : TStream) : String;
procedure SetToNil(var AObj);
function TrimPad(AString : String; ALength : Integer) : String;
function Replace(InThis,This,WithThis : String) : String;

{ TODO : Move these into OSUtilities }
function TempDir : String;
function WindowsDir : String;
function CurrentDir : String;
function SystemDir : String;

function VersionStringToNumber(AVersion : String) : Integer;
function ContainsNumbers(AString : String) : Boolean;

function DateTimeToStrNull(ADateTime : TDateTime) : String;

procedure FileCopy(ASource,ADestination : String; AOverwrite : Boolean);

function IFs(AReturn : String; AIf : Boolean) : String;

implementation

function WindowsDir : String;
var
  PStr : Array[0..4096] of Char;
begin
  GetWindowsDirectory(@PStr,SizeOf(PStr));
  result := StrPas(PStr);
end;

function CurrentDir : String;
var
  PStr : Array[0..4096] of Char;
begin
  GetCurrentDirectory(SizeOf(PStr),@PStr);
  result := StrPas(PStr);
end;

function SystemDir : String;
var
  PStr : Array[0..4096] of Char;
begin
  GetSystemDirectory(@PStr,SizeOf(PStr));
  result := StrPas(PStr);
end;

function TrimTo(AStr : String; ALen : Integer) : String;
begin
  if Length(AStr)>ALen then begin
    AStr := Trim(AStr);
    if Length(AStr)>ALen then begin
      SetLength(AStr,ALen);
    end;
  end;
  result := AStr;
end;

procedure Nop;
begin
  asm
    nop;
  end;
end;

function TempDir : String;
var
  Directory : String;
  DirBuffer : Array[0..255] of Char;
begin
  FillChar(DirBuffer,SizeOf(DirBuffer),0);
  GetEnvironmentVariable('TEMP'#0,DirBuffer,255);
  Directory := StrPas(DirBuffer);
  if Directory='' then begin
    GetEnvironmentVariable('TMP'#0,DirBuffer,255);
    Directory := StrPas(DirBuffer);
  end;
  if Directory='' then begin
    GetWindowsDirectory(DirBuffer,255);
    Directory := StrPas(DirBuffer);
  end;
  if Directory[Length(Directory)]<>'\' then
    Directory := Directory + '\';
    
  TempDir := Directory;
end;

function DebHexToInt(S : String) : Integer;
var
  C,
  Res : Integer;
begin
  {It isn't hexadecimal!!! Some form of stupid debra coding....}
  Res := 0;
  for C := 1 to Length(S) do begin
    Res := (Res SHL 8) OR Ord(S[C]);
  end;
    Result := Res;
end;

function DebIntToHex(I : Integer; MinWidth : Integer) : String;
var
  S   : String;
begin
  {It isn't hexadecimal!!! Some form of stupid debra coding....}
  while I>0 do begin
    S := Chr(I AND $FF) + S;
    I := I SHR 8;
  end;
  while Length(S)<MinWidth do
    S := '0' + S;
  Result := S;
end;

procedure StringToStream(AStream : TStream; AStr : String);
var
  C : Integer;
begin
  C := Length(AStr);
  AStream.Write(C,SizeOf(C));
  if C>0 then
    AStream.Write(AStr[1],C);
end;

function StringFromStream(AStream : TStream) : String;
var
  C : Integer;
  S : String;
begin
  AStream.Read(C,SizeOf(C));
  SetLength(S,C);
  if C>0 then
    AStream.Read(S[1],C);
  StringFromStream := S;
end;

{$HINTS OFF}
procedure SetToNil(var AObj);
begin
  TObject(AObj) := Nil;
end;
{$HINTS ON}

function Spaces(ALength : Integer) : String;
var
  S : String;
begin
  S := '';
  while Length(S)<ALength do
    S := S+' ';
  Result := S;
end;
  
function TrimPad(AString : String; ALength : Integer) : String;
begin
  if Length(AString)>ALength then
    SetLength(AString,ALength)
  else
    AString := AString + Spaces(ALength-Length(AString));
  Result := AString;
end;

function Replace(InThis,This,WithThis : String) : String;
var
  P : Integer;
begin
  P := Pos(This,InThis);
  while P<>0 do begin
    Delete(InThis,P,Length(This));
    Insert(WithThis,InThis,P);
    P := Pos(This,InThis);
  end;
  Result := InThis;
end;

function VersionStringToNumber(AVersion : String) : Integer;
var
  P,Major,Minor,Release,Build : Integer;
begin
  {5.3.1.3 becomes 050300010003 i.e.
   MMIIRRBBBB is the format where M=Major, I=Minor, R=Release, B=Build
   and this fits in with an integer which can have upto
   2147483647
   in it i.e The last version number we could support is 21.47.74.3647}
  try
    AVersion := AVersion+'.';
    P := Pos('.',AVersion);
    Major := StrToInt(Copy(AVersion,1,P-1));
    Delete(AVersion,1,P);
    P := Pos('.',AVersion);
    Minor := StrToInt(Copy(AVersion,1,P-1));
    Delete(AVersion,1,P);
    P := Pos('.',AVersion);
    Release := StrToInt(Copy(AVersion,1,P-1));
    Delete(AVersion,1,P);
    P := Pos('.',AVersion);
    Build := StrToInt(Copy(AVersion,1,P-1));
//    result := (Major*10000000)+(Minor*1000000)+(Release*10000)+Build;
    result := StrToInt(Format('%2.2d%2.2d%2.2d%4.4d',[Major,Minor,Release,Build]));
  except
    result := -1;
  end;
end;

function DateTimeToStrNull(ADateTime : TDateTime) : String;
begin
  if ADateTime=0 then
    result := ''
  else
    result := DateTimeToStr(ADateTime);
end;

function ContainsNumbers(AString : String) : Boolean;
var
  Numbers,
  Letters : Boolean;
  c : Integer;
begin
  Numbers := False;
  Letters := False;
  for C := 1 to Length(AString) do begin
    Letters := Letters or (UpCase(AString[C]) in ['A'..'Z']);
    Numbers := Numbers or (AString[C] in ['0'..'9']);
  end;
  Result := Numbers and Letters;
  result := result or (Lowercase(AString)<>Uppercase(AString));
end;

procedure FileCopy(ASource,ADestination : String; AOverwrite : Boolean);
var
  szS, szD : Array[0..256] of Char;
begin
  StrPCopy(szS,ASource);
  StrPCopy(szD,ADestination);
  CopyFile(szS,szD,not AOverwrite);
end;

function IFs(AReturn : String; AIf : Boolean) : String;
begin
  result := '';
  if AIf then
    result := AReturn;
end;

end.

