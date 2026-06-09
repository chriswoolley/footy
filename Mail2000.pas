(*

Component name...................: Mail2000 (Mail2000.pas)
Classes implemented..............: TPOP2000, TSMTP2000, TMailMessage
Version..........................: 1.2
Status...........................: Beta
Author...........................: Marcello "Panda" Tavares
Comments, bugs, suggestions to...: mpanda@bigfoot.com
Language.........................: English
Platform.........................: Windows 95/98/NT
Requires.........................: Borland Delphi 4.0 with Internet Components


Features
--------

1. Retrieve and delete messages from POP3 servers.

2. Interpret and divide MIME or UUE messages in header, body, alternative
   texts and attachments.

3. Implement methods to create new MIME messages or handle and modify
   retrieved messages for further resending or processing.

4. Enable access to the integral message source for manual manipulation or
   database storing.

5. Send messages to SMTP servers.

6. Support for tunnel proxy servers.


Know limitations
----------------

1. Does not build UUCODE messages.

2. Pretty slow...


How to install
--------------

Create a directory;
Extract archive contents on it;
Open Delphi;
Click File/Close All;
Click Component/Install Component;
In "Unit File Name" select mail2000.pas;
Click Ok;
Select Yes to rebuild package;
Wait for the message saying that the component is installed;
Click File/Close All;
Select Yes to save the package;
Now try to run the demo.


How to use
----------

The better way to learn is looking at the demo source.
Please open and run Demo.dpr
I'm not planning to type a help file.
Fell free to mail your questions to me.


License stuff
-------------

Mail2000 Copyleft 1999

This software is provided as-is, without any express or implied
warranty. In no event will the author be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented, you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated.

2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

3. If you make changes to this software, you must send me the modified
   version.

Please, consider my hard work.


Thanks to
---------

Mariano D. Podesta (marianopodesta@usa.net) - The author of wlPop3
component, from where I copied some decoding routines.

Sergio Kessler (sergio@perio.unlp.edu.ar) - The author of SakEmail
component, from where I based my encoding and smtp algorithms.

Delphi Super Page (http://sunsite.icm.edu.pl/delphi/) - For providing
the best way to find great programs and to join the Delphi community.

Yunarso Anang (yasx@hotmail.com) - For providing some functions for
correct threatment of oriental charsets.

Christian Bormann (chris@xynx.de) - For giving a lot of suggestions
and hard testing of this component.

Anyone interested in help me to improve this component, including you,
just by downloading it.


What's new in 1.1 version
-------------------------

1.  Fixed the threatment of encoded fields in header;
2.  Fixed some fake attachments found in message;
3.  Included a string property "LastMessage" containing the source of
    last message retrieved;
4.  Now decoding file names;
5.  Fixed way to identify kind of host address;
6.  Added support for some tunnel proxy servers (eg via telnet port);
7.  Socket changed to non-blocking to improve communication;
8.  Fixed crashes when decoding encoded labels;
9.  Fixed header decoding with ansi charsets;
10. Fixed crashes when there are deleted messages on server;
11. Now recogning text/??? file attachments;
12. Added Content-ID label at attachment header, now you can reference
    attached files on HTML code e.g. <img src=cid:file.ext>;
13. Improved speed when decoding messages;
14. Thousands of minor bug fixes.


What's new in 1.2 version
-------------------------

1.  Added HELO command when talking to SMTP server;
2.  Changed CCO: fields (in portuguese) to BCC:
3.  It doesn't remove BCC: field after SMTP send anymore;
4.  Some random bugs fixed;

*)

unit Mail2000;

{$BOOLEVAL OFF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  WinSock, ScktComp, Math, Registry, ExtCtrls;

type

  TMailPartList = class;
  TMailMessage = class;
  TSocketTalk = class;

  TMessageSize = array of Integer;

  TSessionState = (stNone, stProxy, stConnect, stUser, stPass, stStat, stList, stRetr, stDele, stHelo, stMail, stRcpt, stData, stSendData, stQuit);
  TTalkError = (teGeneral, teSend, teReceive, teConnect, teDisconnect, teAccept, teTimeout, teNoError);

  TProgressEvent = procedure(Sender: TObject; Total, Current: Integer) of object;
  TEndOfDataEvent = procedure(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean) of object;
  TSocketTalkErrorEvent = procedure(Sender: TObject; SessionState: TSessionState; TalkError: TTalkError) of object;
  TReceiveDataEvent = procedure(Sender: TObject; Sessionstate: TSessionState; Data: String; var ServerResult: Boolean) of object;

  { TMailPart - A recursive class to handle parts, subparts, and the mail by itself }

  TMailPart = class(TComponent)
  private
    FOnProcess : TNotifyEvent;
    FHeader: TStringList {TMailText};
    FBody: TMemoryStream;
    FDecoded: TMemoryStream;
    FBoundary: String;
    FOwnerMessage: TMailMessage;
    FSubPartList: TMailPartList;
    FOwnerPart: TMailPart;

    function GetAttachInfo: String;
    function GetFileName: String;

    procedure SetAttachInfo(AttachInfo: String);
    procedure SetFileName(FileName: String);

    procedure EncodeText;
    procedure EncodeBinary;

    procedure Process;
  public

    constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;

    function GetLabelValue(cLabel: String): String;                           // Get the value of a label. e.g. Label: value
    function GetLabelParamValue(cLabel, Param: String): String;               // Get the value of a label parameter. e.g. Label: xxx; param=value
    function LabelExists(cLabel: String): Boolean;                            // Determine if a label exists
    function LabelParamExists(cLabel, Param: String): Boolean;                // Determine if a label parameter exists

    function Decode: Boolean;                                                 // Decode body in Decoded stream and result true if successful
//    procedure Decode;

    procedure SetLabelValue(cLabel, cValue: String);                          // Set the value of a label
    procedure SetLabelParamValue(cLabel, cParam, cValue: String);             // Set the value of a label parameter

    procedure Fill(Data: PChar; HasHeader: Boolean);                          // Store the data on mail part (divide body, header, determine subparts)
    procedure Remove;                                                         // Delete this mailpart from message

    property OnProcess : TNotifyEvent read FOnProcess write FOnProcess;
    property Header: TStringList {TMailText} read FHeader;                    // The header text
    property Body: TMemoryStream read FBody;                                  // The original body
    property Decoded: TMemoryStream read FDecoded;                            // Stream with the body decoded
    property Boundary: String read FBoundary;                                 // String that divides this mail part from others
    property SubPartList: TMailPartList read FSubPartList;                    // List of subparts of this mail part
    property FileName: String read GetFileName write SetFileName;             // Name of file when this mail part is an attached file
    property AttachInfo: String read GetAttachInfo write SetAttachInfo;       // E.g. application/octet-stream
    property OwnerMessage: TMailMessage read FOwnerMessage;                   // Main message that owns this mail part
    property OwnerPart: TMailPart read FOwnerPart;                            // Father part of this part (can be the main message too)
  end;

  { TMailPartList - Just a collection of TMailPart's }

	TMailPartList = class(TList)
	private

		function Get(const Index: Integer): TMailPart;

	public

		destructor Destroy; override;

		property Items[const Index: Integer]: TMailPart read Get; default;
	end;

  { TMailMessage - A descendant of TMailPart with some tools to handle the mail }

  TMailMessage = class(TMailPart)
  private

    FAttachList: TMailPartList;
    FTextPlain: TStringList;
    FTextHTML: TStringList;
    FTextRTF: TStringList;
    FTextPart: TMailPart;
    FTextPlainPart: TMailPart;
    FTextHTMLPart: TMailPart;
    FTextRTFPart: TMailPart;
    FCharset: String;
    FOnProgress: TProgressEvent;
    FNameCount: Integer;

    FNeedRebuild: Boolean;

    function GetDestName(Field: String; const Index: Integer): String;
    function GetDestAddress(Field: String; const Index: Integer): String;
    function GetDestCount(Field: String): Integer;

    function GetToName(const Index: Integer): String;
    function GetToAddress(const Index: Integer): String;
    function GetToCount: Integer;
    function GetCcName(const Index: Integer): String;
    function GetCcAddress(const Index: Integer): String;
    function GetCcCount: Integer;
    function GetBccName(const Index: Integer): String;
    function GetBccAddress(const Index: Integer): String;
    function GetBccCount: Integer;

    function GetFromName: String;
    function GetFromAddress: String;
    function GetReplyToName: String;
    function GetReplyToAddress: String;
    function GetSubject: String;
    function GetDate: TDateTime;
    function GetMessageId: String;

    procedure AddDest(Field, Name, Address: String);

    procedure PutText(Text: String; Part: TMailPart; Content: String);

    procedure SetSubject(Subject: String);
    procedure SetDate(Date: TDateTime);
    procedure SetMessageId(MessageId: String);

  public

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddTo(Name, Address: String);                                   // Add a To: destination to message header
    procedure AddCc(Name, Address: String);                                   // Add a Cc: destination to message header
    procedure AddBcc(Name, Address: String);                                  // Add a Bcc: destination to message header

    procedure ClearTo;                                                        // Delete the To: field
    procedure ClearCc;                                                        // Delete the Cc: field
    procedure ClearBcc;                                                       // Delete the Bcc: field

    procedure SetFrom(Name, Address: String);                                 // Create/modify the From: field
    procedure SetReplyTo(Name, Address: String);                              // Create/modify the Reply-To: field

    procedure GetAttachList;                                                  // Search for the attachments and text
    procedure RebuildBody;                                                    // Build the mail body according to mailparts
    procedure Reset;                                                          // Clear all stored data in the object
    procedure AttachFile(FileName: String);                                   // Create a mailpart and encode a file on it (doesn't rebuild body)
    procedure SetTextPlain(Text: TStrings);                                   // Create/modify a mailpart for text/plain (doesn't rebuild body)
    procedure SetTextHTML(Text: TStrings);                                    // Create/modify a mailpart for text/html (doesn't rebuild body)
    procedure SetTextRTF(Text: TStrings);                                     // Create/modify a mailpart for text/enriched (doesn't rebuild body)
    procedure RemoveTextPlain;                                                // Remove the first text/plain mailpart (doesn't rebuild body)
    procedure RemoveTextHTML;                                                 // Remove the first text/html mailpart (doesn't rebuild body)
    procedure RemoveTextRTF;                                                  // Remove the first text/enriched mailpart (doesn't rebuild body)

    property ToName[const Index: Integer]: String read GetToName;             // Retrieve the name of To: destination number # (first is zero)
    property ToAddress[const Index: Integer]: String read GetToAddress;       // Retrieve the address of To: destination number #
    property ToCount: Integer read GetToCount;                                // Count the number of To: destinations
    property CcName[const Index: Integer]: String read GetCcName;             // Retrieve the name of Cc: destination number #
    property CcAddress[const Index: Integer]: String read GetCcAddress;       // Retrieve the address of Cc: destination number #
    property CcCount: Integer read GetCcCount;                                // Count the number of Cc: destinations
    property BccName[const Index: Integer]: String read GetBccName;           // Retrieve the name of Bcc: destination number #
    property BccAddress[const Index: Integer]: String read GetBccAddress;     // Retrieve the address of Bcc: destination number #
    property BccCount: Integer read GetBccCount;                              // Count the number of Bcc: destinations

    property FromName: String read GetFromName;                               // Retrieve the From: name
    property FromAddress: String read GetFromAddress;                         // Retrieve the From: address
    property ReplyToName: String read GetReplyToName;                         // Retrieve the Reply-To: name
    property ReplyToAddress: String read GetReplyToAddress;                   // Retrieve the Reply-To: address
    property Subject: String read GetSubject write SetSubject;                // Retrieve or set the Subject: string
    property Date: TDateTime read GetDate write SetDate;                      // Retrieve or set the Date: in TDateTime format
    property MessageId: String read GetMessageId write SetMessageId;          // Retrieve or set the Message-Id:
    property AttachList: TMailPartList read FAttachList;                      // A list of all attached files (need GetAttachList)
    property TextPlain: TStringList read FTextPlain;                          // A StringList with the text/plain from message (need GetAttachList)
    property TextHTML: TStringList read FTextHTML;                            // A StringList with the text/html from message (need GetAttachList)
    property TextRTF: TStringList read FTextRTF;                              // A StringList with the text/enriched from message (need GetAttachList)
    property TextPlainPart: TMailPart read FTextPlainPart;                    // The text/plain part
    property TextHTMLPart: TMailPart read FTextHTMLPart;                      // The text/html part
    property TextRTFPart: TMailPart read FTextRTFPart;                        // The text/enriched part
    property NeedRebuild: Boolean read FNeedRebuild;                          // True if RebuildBody is needed

  published

    property Charset: String read FCharSet write FCharset;                    // Charset to build headers and text (allways 7bit)
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;   // Occurs when storing message in memory
  end;

  { TSocketTalk }

  TSocketTalk = class(TComponent)
  private
    FOnProcess : TNotifyEvent;

    FTimeOut: Integer;
    FExpectedEnd: String;
    FLastResponse: String;
    FDataSize: Integer;
    FPacketSize: Integer;
    FTalkError: TTalkError;
    FSessionState: TSessionState;
    FClientSocket: TClientSocket;
    FWaitingServer: Boolean;
    FTimer: TTimer;
    FServerResult: Boolean;

    FOnProgress: TProgressEvent;
    FOnEndOfData: TEndOfDataEvent;
    FOnSocketTalkError: TSocketTalkErrorEvent;
    FOnReceiveData: TReceiveDataEvent;
    FOnDisconnect: TNotifyEvent;

    procedure SocketRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure SocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure Timer(Sender: TObject);

    procedure Process;
  public

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Talk(Buffer, EndStr: String; SessionState: TSessionState);
    procedure Cancel;
    procedure ForceState(SessionState: TSessionState);
    procedure WaitServer;

    property OnProcess : TNotifyEvent read FOnProcess write FOnProcess;
    property LastResponse: String read FLastResponse;
    property DataSize: Integer read FDataSize write FDataSize;
    property PacketSize: Integer read FPacketSize write FPacketSize;
    property TimeOut: Integer read FTimeOut write FTimeOut;
    property TalkError: TTalkError read FTalkError;
    property ClientSocket: TClientSocket read FClientSocket;
    property ServerResult: Boolean read FServerResult;

    property OnEndOfData: TEndOfDataEvent read FOnEndOfData write FOnEndOfData;
    property OnSocketTalkError: TSocketTalkErrorEvent read FOnSocketTalkError write FOnSocketTalkError;
    property OnReceiveData: TReceiveDataEvent read FOnReceiveData write FOnReceiveData;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnDisconnect: TNotifyEvent read FOnDisconnect write FOnDisconnect;
  end;

  { TPOP2000 }

  TPOP2000 = class(TComponent)
  private

    FMailMessage: TMailMessage;

    FSessionMessageCount: Integer;
    FSessionMessageSize: TMessageSize;
    FSessionConnected: Boolean;
    FSessionLogged: Boolean;
    FLastMessage: String;
    FSocketTalk: TSocketTalk;

    FUserName: String;
    FPassword: String;
    FPort: Integer;
    FHost: String;
    FProxyPort: Integer;
    FProxyHost: String;
    FProxyUsage: Boolean;
    FProxyString: String;

    procedure EndOfData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
    procedure SocketTalkError(Sender: TObject; SessionState: TSessionState; TalkError: TTalkError);
    procedure ReceiveData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
    procedure SocketDisconnect(Sender: TObject);

    function GetTimeOut: Integer;
    procedure SetTimeOut(Value: Integer);

    function GetProgress: TProgressEvent;
    procedure SetProgress(Value: TProgressEvent);

    function GetLastResponse: String;

  public

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Connect: Boolean;                                                // Connect to mail server
    function Login: Boolean;                                                  // Autenticate to mail server
    function Quit: Boolean;                                                   // Logout and disconnect

    function RetrieveMessage(Number: Integer): Boolean;                       // Retrieve mail number # and put in MailMessage
    function DeleteMessage(Number: Integer): Boolean;                         // Delete mail number #

    property SessionMessageCount: Integer read FSessionMessageCount;          // Number of messages found on server
    property SessionMessageSize: TMessageSize read FSessionMessageSize;       // Dynamic array with size of the messages
    property SessionConnected: Boolean read FSessionConnected;                // True if conencted to server
    property SessionLogged: Boolean read FSessionLogged;                      // True if autenticated on server
    property LastMessage: String read FLastMessage;                           // Last integral message text
    property LastResponse: String read GetLastResponse;                       // Last string received from server

  published

    property UserName: String read FUserName write FUserName;                 // User name to login on server
    property Password: String read FPassword write FPassword;                 // Password
    property Port: Integer read FPort write FPort;                            // Port (usualy 110)
    property Host: String read FHost write FHost;                             // Host address
    property ProxyPort: Integer read FProxyPort write FProxyPort;             // Port to connect on proxy server
    property ProxyHost: String read FProxyHost write FProxyHost;              // Address of proxy server
    property ProxyUsage: Boolean read FProxyUsage write FProxyUsage;          // True when using a proxy server to get mail
    property ProxyString: String read FProxyString write FProxyString;        // String to inform proxy server where to connect (%h% Host, %p% Port, %u% User)
    property MailMessage: TMailMessage read FMailMessage write FMailMessage;  // Message retrieved
    property TimeOut: Integer read GetTimeOut write SetTimeOut;               // Max time to wait for server reply in seconds
    property OnProgress: TProgressEvent read GetProgress write SetProgress;   // Occurs when receiving data from server
  end;

  { TSMTP2000 }

  TSMTP2000 = class(TComponent)
  private

    FMailMessage: TMailMessage;

    FSessionConnected: Boolean;
    FSocketTalk: TSocketTalk;
    FPacketSize: Integer;

    FOnProcess : TNotifyEvent;
    FPort: Integer;
    FHost: String;
    FProxyPort: Integer;
    FProxyHost: String;
    FProxyUsage: Boolean;
    FProxyString: String;

    procedure EndOfData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
    procedure SocketTalkError(Sender: TObject; SessionState: TSessionState; TalkError: TTalkError);
    procedure ReceiveData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
    procedure SocketDisconnect(Sender: TObject);

    function GetTimeOut: Integer;
    procedure SetTimeOut(Value: Integer);

    function GetProgress: TProgressEvent;
    procedure SetProgress(Value: TProgressEvent);

    function GetLastResponse: String;

  public

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Connect: Boolean;                                                // Connect to mail server
    function Quit: Boolean;                                                   // Disconnect

    function SendMessage: Boolean;                                            // Send MailMessage to server

    property SessionConnected: Boolean read FSessionConnected;                // True if conencted to server
    property LastResponse: String read GetLastResponse;                       // Last string received from server

  published

    property Process : TNotifyEvent read FOnProcess write FOnProcess;
    property Port: Integer read FPort write FPort;                            // Port (usualy 25)
    property Host: String read FHost write FHost;                             // Host address
    property ProxyPort: Integer read FProxyPort write FProxyPort;             // Port to connect on proxy server
    property ProxyHost: String read FProxyHost write FProxyHost;              // Address of proxy server
    property ProxyUsage: Boolean read FProxyUsage write FProxyUsage;          // True when using a proxy server to send mail
    property ProxyString: String read FProxyString write FProxyString;        // String to inform proxy server where to connect (%h% Host, %p% Port)
    property TimeOut: Integer read GetTimeOut write SetTimeOut;               // Max time to wait for a response in seconds
    property MailMessage: TMailMessage read FMailMessage write FMailMessage;  // Message to send
    property PacketSize: Integer read FPacketSize write FPacketSize;          // Size of packets to send to server
    property OnProgress: TProgressEvent read GetProgress write SetProgress;   // Occurs when sending data to server
  end;

procedure Register;

implementation

procedure Register;
begin

  RegisterComponents('Mail2000', [TPOP2000, TSMTP2000, TMailMessage]);
end;

{ Very useful functions ====================================================== }

function DecodeLine7Bit(Texto: String): String; forward;
function EncodeLine7Bit(Texto, Charset: String): String; forward;
function DecodeQuotedPrintable(Texto: String): String; forward;
function EncodeQuotedPrintable(Texto: String; HeaderLine: Boolean): String; forward;
function DecodeUUCODE(Encoded: PChar; Decoded: TMemoryStream): Boolean; forward;
function DecodeLineUUCODE(const Buffer: String; Decoded: PChar): Integer; forward;
function DecodeLineBASE64(const Buffer: String; Decoded: PChar): Integer; forward;
function EncodeBASE64(Encoded: TMemoryStream {TMailText}; Decoded: TMemoryStream): Integer; forward;
function NormalizeLabel(Texto: String): String; forward;
function LabelValue(cLabel: String): String; forward;
function WriteLabelValue(cLabel, Value: String): String; forward;
function LabelParamValue(cLabel, cParam: String): String; forward;
function WriteLabelParamValue(cLabel, cParam, Value: String): String; forward;
function GetTimeZoneBias: Double; forward;
function PadL(Str: String; Tam: Integer; PadStr: String): String; forward;
function GetMimeType(FileName: String): String; forward;
function GetMimeExtension(MimeType: String): String; forward;
function GenerateBoundary: String; forward;
function SeekSL(Lista: TStringList; Chave: String): Integer; forward;
procedure DataLine(var Data, Line: String; var nPos: Integer); forward;
procedure DataLinePChar(const Data: PChar; const TotalLength: Integer; var LinePos, LineLen: Integer; var Line: PChar; var DataEnd: Boolean); forward;
procedure WrapSL(Source: TStringList; var Dest: String; Margin: Integer); forward;
function IsIPAddress(SS: String): Boolean; forward;
function FindReplace(Source, Old, New: String): String; forward;
function TrimSpace(const S: string): string; forward;
function TrimLeftSpace(const S: string): string; forward;
function TrimRightSpace(const S: string): string; forward;

// Decode an encoded field e.g. =?iso-8859-1?x?xxxxxx=?=

function DecodeLine7Bit(Texto: String): String;
var
  Buffer: PChar;
  Encoding: Char;
  Size: Integer;
  nPos0: Integer;
  nPos1: Integer;
  nPos2: Integer;
  nPos3: Integer;
  Found: Boolean;

begin

  Result := TrimSpace(Texto);

  repeat

    nPos0 := Pos('=?', Result);
    Found := False;

    if nPos0 > 0 then
    begin

      nPos1 := Pos('?', Copy(Result, nPos0+2, Length(Result)))+nPos0+1;
      nPos2 := Pos('?=', Copy(Result, nPos1+1, Length(Result)))+nPos1;
      nPos3 := Pos('?', Copy(Result, nPos2+1, Length(Result)))+nPos2;

      if nPos3 > nPos2 then
      begin

        if Length(Result) > nPos3 then
        begin

          if Result[nPos3+1] = '=' then
          begin

            nPos2 := nPos3;
          end;
        end;
      end;

      if (nPos1 > nPos0) and (nPos2 > nPos1) then
      begin

        Texto := Copy(Result, nPos1+1, nPos2-nPos1-1);

        if (Texto[2] = '?') and (UpCase(Texto[1]) in ['B', 'Q', 'U']) then
        begin

          Encoding := UpCase(Texto[1]);
        end
        else
        begin

          Encoding := 'Q';
        end;

        Texto := Copy(Texto, 3, Length(Texto)-2);
        
        case Encoding of

          'B':
          begin

            GetMem(Buffer, Length(Texto));
            Size := DecodeLineBASE64(Texto, Buffer);
            Buffer[Size] := #0;
            Texto := String(Buffer);
          end;

          'Q':
          begin

            while Pos('_', Texto) > 0 do
              Texto[Pos('_', Texto)] := #32;

            Texto := DecodeQuotedPrintable(Texto);
          end;

          'U':
          begin

            GetMem(Buffer, Length(Texto));
            Size := DecodeLineUUCODE(Texto, Buffer);
            Buffer[Size] := #0;
            Texto := String(Buffer);
          end;
        end;

        Result := Copy(Result, 1, nPos0-1)+Texto+Copy(Result,nPos2+2,Length(Result));
        Found := True;
      end;
    end;

  until not Found;
end;

// Encode an ISO8859-1 encoded line e.g. =?iso-8859-1?x?xxxxxx=?=

function EncodeLine7Bit(Texto, Charset: String): String;
var
  Loop: Integer;
  Encode: Boolean;
begin

  Encode := False;

  for Loop := 1 to Length(Texto) do
    if (Ord(Texto[Loop]) > 127) or (Ord(Texto[Loop]) < 32) then
    begin

      Encode := True;
      Break;
    end;

  if Encode then
    Result := '=?'+Charset+'?Q?'+EncodeQuotedPrintable(Texto, True)+'?='
  else
    Result := Texto;
end;

// Decode a quoted-printable encoded string

function DecodeQuotedPrintable(Texto: String): String;
var
  nPos: Integer;
  nLastPos: Integer;
  lFound: Boolean;

begin

  Result := Texto;

  lFound := True;
  nLastPos := 0;

  while lFound do
  begin

    lFound := False;

    if nLastPos < Length(Result) then
      nPos := Pos('=', Copy(Result, nLastPos+1, Length(Result)-nLastPos))+nLastPos
    else
      nPos := 0;

    if (nPos < (Length(Result)-1)) and (nPos > nLastPos) then
    begin

      if (Result[nPos+1] in ['A'..'F', '0'..'9']) and (Result[nPos+2] in ['A'..'F', '0'..'9']) then
      begin

        Insert(Char(StrToInt('$'+Result[nPos+1]+Result[nPos+2])), Result, nPos);
        Delete(Result, nPos+1, 3);
      end
      else
      begin

        if (Result[nPos+1] = #13) and (Result[nPos+2] = #10) then
        begin

          Delete(Result, nPos, 3);
        end
        else
        begin

          if (Result[nPos+1] = #10) and (Result[nPos+2] = #13) then
          begin

            Delete(Result, nPos, 3);
          end
          else
          begin

            if (Result[nPos+1] = #13) and (Result[nPos+2] <> #10) then
            begin

              Delete(Result, nPos, 2);
            end
            else
            begin

              if (Result[nPos+1] = #10) and (Result[nPos+2] <> #13) then
              begin

                Delete(Result, nPos, 2);
              end;
            end;
          end;
        end;
      end;

      lFound := True;
      nLastPos := nPos;
    end
    else
    begin

      if nPos = Length(Result) then
      begin

        Delete(Result, nPos, 1);
      end;
    end;
  end;
end;

// Encode a string in quoted-printable format

function EncodeQuotedPrintable(Texto: String; HeaderLine: Boolean): String;
var
  nPos: Integer;
  LineLen: Integer;

begin

  Result := '';
  LineLen := 0;

  for nPos := 1 to Length(Texto) do
  begin

    if (Texto[nPos] > #127) or
       (Texto[nPos] = '=') or
       ((Texto[nPos] <= #32) and HeaderLine) or
       ((Texto[nPos] = '"') and HeaderLine) then
    begin

      Result := Result + '=' + PadL(Format('%2x', [Ord(Texto[nPos])]), 2, '0');
      Inc(LineLen, 3);
    end
    else
    begin

      Result := Result + Texto[nPos];
      Inc(LineLen);
    end;

    if Texto[nPos] = #13 then LineLen := 0;

    if (LineLen >= 70) and (not HeaderLine) then
    begin

      Result := Result + '='#13#10;
      LineLen := 0;
    end;
  end;
end;

// Decode an UUCODE encoded line

function DecodeLineUUCODE(const Buffer: String; Decoded: PChar): Integer;
const
	CHARS_PER_LINE = 45;
	Table: String = '`!"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_';

var
	A24Bits: array[0..8 * CHARS_PER_LINE] of Boolean;
	i, j, k, b: Word;
	LineLen, ActualLen: Byte;

	function p_ByteFromTable(Ch: Char): Byte;
	var
		ij: Integer;
	begin

		ij := Pos(Ch, Table);

		if (ij > 64) or (ij = 0) then
		begin
			if Ch = #32 then
				Result := 0 else
				raise Exception.Create('UUCODE: Message format error');
		end else
			Result := ij - 1;
	end;

begin

  if Buffer = '' then
  begin

    Result := 0;
    Exit;
  end;

	LineLen := p_ByteFromTable(Buffer[1]);
	ActualLen := 4 * LineLen div 3;

	FillChar(A24Bits, 8 * CHARS_PER_LINE + 1, 0);
	Result := LineLen;

	if ActualLen <> (4 * CHARS_PER_LINE div 3) then
		ActualLen := Length(Buffer) - 1;

	k := 0;
	for i := 2 to ActualLen + 1 do
	begin
		b := p_ByteFromTable(Buffer[i]);
		for j := 5 downto 0 do
		begin
			A24Bits[k] := b and (1 shl j) > 0;
			Inc(k);
		end;
	end;

	k := 0;
	for i := 1 to CHARS_PER_LINE do
	begin
		b := 0;
		for j := 7 downto 0 do
		begin
			if A24Bits[k] then b := b or (1 shl j);
			Inc(k);
		end;
		Decoded[i-1] := Char(b);
	end;
end;

// Decode an UUCODE text

function DecodeUUCODE(Encoded: PChar; Decoded: TMemoryStream): Boolean;
var
  nTL, nPos, nLen: Integer;
  Line: PChar;
  LineDec: array[0..79] of Char;
  LineLen: Integer;
  DataEnd: Boolean;

begin

  Decoded.Clear;

  DataEnd := False;
  nPos := -1;
  nTL := StrLen(Encoded);

  DataLinePChar(Encoded, nTL, nPos, nLen, Line, DataEnd);

  while not DataEnd do
  begin

    if nLen > 0 then
    begin

      LineLen := DecodeLineUUCODE(String(Line), LineDec);

      if LineLen > 0 then
        Decoded.Write(LineDec[0], LineLen);
    end;

    DataLinePChar(Encoded, nTL, nPos, nLen, Line, DataEnd);
  end;

  Result := True;
end;

// Decode a BASE64 encoded line

function DecodeLineBASE64(const Buffer: String; Decoded: PChar): Integer;
var
  A1: array[1..4] of Byte;
  B1: array[1..3] of Byte;
  I, J: Integer;
  BytePtr, RealBytes: Integer;

begin

  BytePtr := 0;
  Result := 0;

  for J := 1 to Length(Buffer) do
  begin

    Inc(BytePtr);

    case Buffer[J] of

      'A'..'Z': A1[BytePtr] := Ord(Buffer[J])-65;

      'a'..'z': A1[BytePtr] := Ord(Buffer[J])-71;

      '0'..'9': A1[BytePtr] := Ord(Buffer[J])+4;

      '+': A1[BytePtr] := 62;

      '/': A1[BytePtr] := 63;

      '=': A1[BytePtr] := 64;
    end;

    if BytePtr = 4 then
    begin

      BytePtr := 0;
      RealBytes := 3;

      if A1[1] = 64 then RealBytes:=0;

      if A1[3] = 64 then
      begin

        A1[3] := 0;
        A1[4] := 0;
        RealBytes := 1;
      end;

      if A1[4] = 64 then
      begin

        A1[4] := 0;
        RealBytes := 2;
      end;

      B1[1] := A1[1]*4 + (A1[2] div 16);
      B1[2] := (A1[2] mod 16)*16+(A1[3] div 4);
      B1[3] := (A1[3] mod 4)*64 + A1[4];

      for I := 1 to RealBytes do
      begin

        Decoded[Result+I-1] := Chr(B1[I]);
      end;

      Inc(Result, RealBytes);
    end;
  end;
end;

// Padronize header labels; remove double spaces, decode quoted text, lower the cases, indentify mail addresses

function NormalizeLabel(Texto: String): String;
const
  EncLabels: String = 'Content-Type:Content-Transfer-Encoding:Content-Disposition:';

var
  Quote: Boolean;
  Quoted: String;
  Loop: Integer;
  lLabel: Boolean;
  sLabel: String;
  Value: String;

begin

  Quote := False;
  lLabel := True;
  Value := '';
  sLabel := '';

  for Loop := 1 to Length(Texto) do
  begin

    if (Texto[Loop] = '"') and (not lLabel) then
    begin

      Quote := not Quote;

      if Quote then
      begin

        Quoted := '';
      end
      else
      begin

        Value := Value + Quoted;
      end;
    end;

    if not Quote then
    begin

      if lLabel then
      begin

        if (sLabel = '') or (sLabel[Length(sLabel)] = '-') then
          sLabel := sLabel + UpCase(Texto[Loop])
        else
          if (Copy(sLabel, Length(sLabel)-1, 2) = '-I') and (UpCase(Texto[Loop]) = 'D') and
             (Loop < Length(Texto)) and (Texto[Loop+1] = ':') then
            sLabel := sLabel + 'D'
          else
            sLabel := sLabel + LowerCase(Texto[Loop]);

        if Texto[Loop] = ':' then
        begin

          lLabel := False;
          Value := '';
        end;
      end
      else
      begin

        if Texto[Loop] = #32 then
        begin

          Value := TrimRightSpace(Value) + #32;
        end
        else
        begin

          if (not lLabel) and (Pos(sLabel, EncLabels) > 0) then
            Value := Value + LowerCase(Texto[Loop]);

          if (not lLabel) and (Pos(sLabel, EncLabels) = 0) then
            Value := Value + Texto[Loop];
        end;
      end;
    end
    else
    begin

      Quoted := Quoted + Texto[Loop];
    end;
  end;

  Result := TrimSpace(sLabel)+' '+TrimSpace(Value);
end;

// Return the value of a label; e.g. Label: value

function LabelValue(cLabel: String): String;
var
  Loop: Integer;
  Quote: Boolean;
  Value: Boolean;
  Ins: Boolean;

begin

  Quote := False;
  Value := False;
  Result := '';

  for Loop := 1 to Length(cLabel) do
  begin

    Ins := True;

    if cLabel[Loop] = '"' then
    begin

      Quote := not Quote;
      Ins := False;
    end;

    if not Quote then
    begin

      if (cLabel[Loop] = ':') and (not Value) then
      begin

        Value := True;
        Ins := False;
      end
      else
      begin

        if (cLabel[Loop] = ';') and Value then
        begin

          Break;
        end;
      end;
    end;

    if Ins and Value then
    begin

      Result := Result + cLabel[Loop];
    end;
  end;

  Result := TrimSpace(Result);

  if (Copy(Result, 1, 1) = '"') and (Copy(Result, Length(Result), 1) = '"') then
    Result := Copy(Result, 2, Length(Result)-2);
end;

// Set the value of a label;

function WriteLabelValue(cLabel, Value: String): String;
var
  Loop: Integer;
  Quote: Boolean;
  ValPos, ValLen: Integer;

begin

  Quote := False;
  ValPos := 0;
  ValLen := -1;

  for Loop := 1 to Length(cLabel) do
  begin

    if cLabel[Loop] = '"' then
    begin

      Quote := not Quote;
    end;

    if not Quote then
    begin

      if (cLabel[Loop] = ':') and (ValPos = 0) then
      begin

        ValPos := Loop+1;
      end
      else
      begin

        if (cLabel[Loop] = ';') and (ValPos > 0) then
        begin

          ValLen := Loop - ValPos;
          Break;
        end;
      end;
    end;
  end;

  Result := cLabel;

  if (ValLen < 0) and (ValPos > 0) then
    ValLen := Length(cLabel) - ValPos + 1;

  if ValPos > 0 then
  begin

    Delete(Result, ValPos, ValLen);
    Insert(' '+TrimSpace(Value), Result, ValPos);
  end;
end;

// Return the value of a label parameter; e.g. Label: xxx; param=value

function LabelParamValue(cLabel, cParam: String): String;
var
  Loop: Integer;
  Quote: Boolean;
  Value: Boolean;
  Params: Boolean;
  ParamValue: Boolean;
  Ins: Boolean;
  Param: String;

begin

  Quote := False;
  Value := False;
  Params := False;
  ParamValue := False;

  Param := '';
  Result := '';

  cLabel := TrimSpace(cLabel);

  if Copy(cLabel, Length(cLabel), 1) <> ';' then cLabel := cLabel + ';';

  for Loop := 1 to Length(cLabel) do
  begin

    Ins := True;

    if cLabel[Loop] = '"' then
    begin

      Quote := not Quote;
      Ins := False;
    end;

    if not Quote then
    begin

      if (cLabel[Loop] = ':') and (not Value) and (not Params) then
      begin

        Value := True;
        Params := False;
        ParamValue := False;
        Ins := False;
      end
      else
      begin

        if (cLabel[Loop] = ';') and (Value or Params) then
        begin

          Params := True;
          Value := False;
          ParamValue := False;
          Param := '';
          Ins := False;
        end
        else
        begin

          if (cLabel[Loop] = '=') and Params then
          begin

            ParamValue := UpperCase(TrimSpace(Param)) = UpperCase(TrimSpace(cParam));
            Ins := False;
            Param := '';
          end;
        end;
      end;
    end;

    if Ins and ParamValue then
    begin

      Result := Result + cLabel[Loop];
    end;

    if Ins and (not ParamValue) and Params then
    begin

      Param := Param + cLabel[Loop];
    end;
  end;

  Result := TrimSpace(Result);

  if (Copy(Result, 1, 1) = '"') and (Copy(Result, Length(Result), 1) = '"') then
    Result := Copy(Result, 2, Length(Result)-2);
end;

// Set the value of a label parameter;

function WriteLabelParamValue(cLabel, cParam, Value: String): String;
var
  Loop: Integer;
  Quote: Boolean;
  LabelValue: Boolean;
  Params: Boolean;
  ValPos, ValLen: Integer;
  Ins: Boolean;
  Param: String;

begin

  Quote := False;
  LabelValue := False;
  Params := False;
  ValPos := 0;
  ValLen := -1;

  Param := '';
  Result := '';

  cLabel := TrimSpace(cLabel);

  for Loop := 1 to Length(cLabel) do
  begin

    Ins := True;

    if cLabel[Loop] = '"' then
    begin

      Quote := not Quote;
      Ins := False;
    end;

    if not Quote then
    begin

      if (cLabel[Loop] = ':') and (not LabelValue) and (not Params) then
      begin

        LabelValue := True;
        Params := False;
        ValPos := 0;
        ValLen := 0;
        Ins := False;
      end
      else
      begin

        if (cLabel[Loop] = ';') and (LabelValue or Params) then
        begin

          if Params and (ValPos > 0) then
          begin

            ValLen := Loop - ValPos;
            Break;
          end;

          Params := True;
          LabelValue := False;
          Param := '';
          Ins := False;
        end
        else
        begin

          if (cLabel[Loop] = '=') and Params then
          begin

            if UpperCase(TrimSpace(Param)) = UpperCase(TrimSpace(cParam)) then
            begin

              ValPos := Loop+1;
              ValLen := 0;
            end;

            Ins := False;
            Param := '';
          end;
        end;
      end;
    end;

    if Ins and (ValPos = 0) and Params then
    begin

      Param := Param + cLabel[Loop];
    end;
  end;

  Result := cLabel;

  if ValPos = 0 then
  begin

    Result := TrimSpace(Result) + '; ' + TrimSpace(cParam) + '=' + TrimSpace(Value);
  end
  else
  begin

    if (ValLen < 0) and (ValPos > 0) then
      ValLen := Length(cLabel) - ValPos + 1;

    Delete(Result, ValPos, ValLen);
    Insert(TrimSpace(Value), Result, ValPos);

    if Result[Length(Result)] = ';' then
      Delete(Result, Length(Result), 1);
  end;
end;

// Return the Timezone adjust in days

function GetTimeZoneBias: Double;
var
  TzInfo: TTimeZoneInformation;

begin

  case GetTimeZoneInformation(TzInfo) of

    1: Result := - (TzInfo.StandardBias + TzInfo.Bias) / (24*60);

    2: Result := - (TzInfo.DaylightBias + TzInfo.Bias) / (24*60);

    else Result := 0;
  end;
end;

// Fills left of string with char

function PadL(Str: String; Tam: Integer; PadStr: String): String;
var
  TempStr: String;

begin

  TempStr := TrimLeftSpace(Str);

  if Length(TempStr) <= Tam then
  begin

    while Length(TempStr) < Tam do
      TempStr := PadStr + TempStr;
  end
  else
  begin

    TempStr := Copy(TempStr, Length(TempStr) - Tam + 1, Tam);
  end;

  Result := TempStr;
end;

// Get mime type of a file extension

function GetMimeType(FileName: String): String;
var
  Key: string;

begin

  Result := '';

  with TRegistry.Create do
    try

      RootKey := HKEY_CLASSES_ROOT;
      Key := ExtractFileExt(FileName);

      if KeyExists(Key) then
      begin

        OpenKey(Key,false);
        Result := ReadString('Content Type');
        CloseKey;
      end;

    finally

      if Result = '' then
        Result := 'application/octet-stream';

      Free;
    end;
end;

// Get file extension of a mime type

function GetMimeExtension(MimeType: String): String;
var
  Key: string;

begin

  Result := '';

  with TRegistry.Create do
    try

      RootKey := HKEY_CLASSES_ROOT;

      if OpenKey('MIME\Database\Content Type', False) then
      begin

        Key := MimeType;

        if KeyExists(Key) then
        begin

          OpenKey(Key,false);
          Result := ReadString('Extension');
          CloseKey;
        end;
      end;

    finally

      if Result = '' then
        Result := '.txt';

      Free;
    end;
end;

// Generate a random boundary

function GenerateBoundary: String;
begin

  Result := '---Mail2000.'+PadL(Format('%8x', [Random($FFFFFFFF)]), 8, '0')+FormatDateTime('.yyyy.mm.dd.hh.nn.ss', Now);
end;

// Encode in base64

function EncodeBASE64(Encoded: TMemoryStream {TMailText}; Decoded: TMemoryStream): Integer;
const
  _Code64: String[64] =
    ('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/');
var
  I: LongInt;
  B: array[0..2279] of Byte;
  J, K, L, M, Quads: Integer;
  Stream: string[76];
  EncLine: String;

begin

  Encoded.Clear;

  Stream := '';
  Quads := 0;
  J := Decoded.Size div 2280;

  Decoded.Position := 0;

  for I := 1 to J do
  begin

    Decoded.Read(B, 2280);

    for M := 0 to 39 do
    begin

      for K := 0 to 18 do
      begin

        L:= 57*M + 3*K;

        Stream[Quads+1] := _Code64[(B[L] div 4)+1];
        Stream[Quads+2] := _Code64[(B[L] mod 4)*16 + (B[L+1] div 16)+1];
        Stream[Quads+3] := _Code64[(B[L+1] mod 16)*4 + (B[L+2] div 64)+1];
        Stream[Quads+4] := _Code64[B[L+2] mod 64+1];

        Inc(Quads, 4);

        if Quads = 76 then
        begin

          Stream[0] := #76;
          EncLine := Stream+#13#10;
          Encoded.Write(EncLine[1], Length(EncLine));
          Quads := 0;
        end;
      end;
    end;
  end;

  J := (Decoded.Size mod 2280) div 3;

  for I := 1 to J do
  begin

    Decoded.Read(B, 3);

    Stream[Quads+1] := _Code64[(B[0] div 4)+1];
    Stream[Quads+2] := _Code64[(B[0] mod 4)*16 + (B[1] div 16)+1];
    Stream[Quads+3] := _Code64[(B[1] mod 16)*4 + (B[2] div 64)+1];
    Stream[Quads+4] := _Code64[B[2] mod 64+1];

    Inc(Quads, 4);

    if Quads = 76 then
    begin

      Stream[0] := #76;
      EncLine := Stream+#13#10;
      Encoded.Write(EncLine[1], Length(EncLine));
      Quads := 0;
    end;
  end;

  if (Decoded.Size mod 3) = 2 then
  begin

    Decoded.Read(B, 2);

    Stream[Quads+1] := _Code64[(B[0] div 4)+1];
    Stream[Quads+2] := _Code64[(B[0] mod 4)*16 + (B[1] div 16)+1];
    Stream[Quads+3] := _Code64[(B[1] mod 16)*4 + 1];
    Stream[Quads+4] := '=';

    Inc(Quads, 4);
  end;

  if (Decoded.Size mod 3) = 1 then
  begin

    Decoded.Read(B, 1);

    Stream[Quads+1] := _Code64[(B[0] div 4)+1];
    Stream[Quads+2] := _Code64[(B[0] mod 4)*16 + 1];
    Stream[Quads+3] := '=';
    Stream[Quads+4] := '=';
    Inc(Quads, 4);
  end;

  Stream[0] := Chr(Quads);

  if Quads > 0 then
  begin

    EncLine := Stream+#13#10;
    Encoded.Write(EncLine[1], Length(EncLine));
  end;

  Result := Encoded.Size;
end;

// Search in a StringList

function SeekSL(Lista: TStringList; Chave: String): Integer;
var
  nPos: Integer;
  lAchou: Boolean;
  Casas: Integer;
  Temp: String;

begin

  Casas := Length(Chave);
  lAchou := False;
  nPos := 0;

  try

    if Lista <> nil then
    begin

      while (not lAchou) and (nPos < Lista.Count) do
      begin

        Temp := Lista[nPos];
        lAchou := UpperCase(Copy(Temp, 1, Casas)) = UpperCase(Chave);

        if not lAchou then
          Inc(nPos);
      end;
    end;

  finally

    if lAchou then
      result := nPos
    else
      result := -1;
  end;
end;

// Search lines into a string

procedure DataLine(var Data, Line: String; var nPos: Integer);
begin

  Line := '';

  while True do
  begin

    Line := Line + Data[nPos];
    Inc(nPos);

    if nPos > Length(Data) then
    begin

      nPos := -1;
      Break;
    end
    else
    begin

      if Length(Line) >= 2 then
      begin

        if (Line[Length(Line)-1] = #13) and (Line[Length(Line)] = #10) then
        begin

          Break;
        end;
      end;
    end;
  end;
end;

// Search lines into a string
// I need to do in this confusing way in order to improve performance

procedure DataLinePChar(const Data: PChar; const TotalLength: Integer; var LinePos, LineLen: Integer; var Line: PChar; var DataEnd: Boolean); assembler;
begin

  if LinePos >= 0 then
  begin

    Data[LinePos+LineLen] := #13;
    LinePos := LinePos+LineLen+2;
    LineLen := 0;
  end
  else
  begin

    LinePos := 0;
    LineLen := 0;
  end;

  while (LinePos+LineLen) < TotalLength do
  begin

    if Data[LinePos+LineLen] = #13 then
    begin

      if (LinePos+LineLen+1) < TotalLength then
      begin

        if Data[LinePos+LineLen+1] = #10 then
        begin

          Data[LinePos+LineLen] := #0;
          Line := @Data[LinePos];
          Exit;
        end;
      end;
    end;

    Inc(LineLen);
  end;

  if LinePos < TotalLength then
    Line := @Data[LinePos]
  else
    DataEnd := True;
end;

// Wrap long lines in a StringList

procedure WrapSL(Source: TStringList; var Dest: String; Margin: Integer);
var
  Buffer: PChar;
  Loop: Integer;
  Line: String;
  Quote: Boolean;

begin

  Buffer := Source.GetText;
  Line := '';
  Dest := '';
  Quote := False;

  for Loop := 0 to StrLen(Buffer)-1 do
  begin

    if Buffer[Loop] = '"' then
      Quote := not Quote;

    Line := Line + Buffer[Loop];

    if (Loop > 0) then
    begin

      if (Buffer[Loop] = #10) and (Buffer[Loop-1] = #13) then
      begin

        Dest := Dest + Line;
        Line := '';
      end;
    end;

    if (Length(Line) >= Margin) and (Buffer[Loop] = #32) and (not Quote) then
    begin

      Dest := Dest + Copy(Line, 1, Length(Line)-1) + #13#10;
      Line := #9;
    end;
  end;
end;

// Determine if string is a numeric IP or not (Thanks to Hou Yg yghou@yahoo.com)

function IsIPAddress(SS: String): Boolean;
var
  S,S1: String;
  P: Integer;

begin

  S1 := S;
  Result := False;
  P := Pos('.', S1);

  if P = 0 then
   Exit;

  while P > 0 do
  begin

    S := Copy(s1,1,p-1);
    S1 := copy(s1,p+1,Length(s1));
    P := StrToIntDef(s,-1);
    if P = -1 then
     Exit;

    P := Pos('.', S1);
  end;

  Result := True;
end;

// Find and replace substrings

function FindReplace(Source, Old, New: String): String;
var
  Position: Integer;

  function Stuff(Source: String; Position, DelCount: Integer; InsString: String): String;
  begin

    result := Copy(Source, 1, Position-1) + InsString +
              Copy(Source, Position+DelCount, Length(Source));
  end;

begin

  repeat
  begin

    Position := Pos(Old, Source);

    if Position > 0 then
      Source := Stuff(Source, Position, Length(Old), New);
  end
  until Position = 0;

  Result := Source;
end;

// Remove leading and trailing spaces from string
// Thanks to Yunarso Anang (yasx@hotmail.com)

function TrimSpace(const S: string): string;
var
  I, L: Integer;

begin

  L := Length(S);
  I := 1;

  while (I <= L) and (S[I] = ' ') do
    Inc(I);

  if I > L then Result := '' else
  begin

    while S[L] = ' ' do
      Dec(L);

    Result := Copy(S, I, L - I + 1);
  end;
end;

// Remove left spaces from string
// Thanks to Yunarso Anang (yasx@hotmail.com)

function TrimLeftSpace(const S: string): string;
var
  I, L: Integer;

begin

  L := Length(S);
  I := 1;

  while (I <= L) and (S[I] = ' ') do
    Inc(I);

  Result := Copy(S, I, Maxint);
end;

// Remove right spaces from string
// Thanks to Yunarso Anang (yasx@hotmail.com)

function TrimRightSpace(const S: string): string;
var
  I: Integer;

begin

  I := Length(S);

  while (I > 0) and (S[I] = ' ') do
    Dec(I);

  Result := Copy(S, 1, I);
end;

{ TMailPart ================================================================== }

// Initialize MailPart

constructor TMailPart.Create(AOwner: TComponent);
begin

  FHeader := TStringList.Create;
  FBody := TMemoryStream.Create;
  FDecoded := TMemoryStream.Create;
  FSubPartList := TMailPartList.Create;
  FOwnerPart := nil;
  FOwnerMessage := nil;

  inherited Create(AOwner);
end;

// Finalize MailPart

destructor TMailPart.Destroy;
var
  Loop: Integer;

begin

  for Loop := 0 to FSubPartList.Count-1 do
    FSubPartList.Items[Loop].Destroy;

  FHeader.Free;
  FBody.Free;
  FDecoded.Free;
  FSubPartList.Free;

  inherited Destroy;
end;

// Return the value of a label from the header like "To", "Subject"

function TMailPart.GetLabelValue(cLabel: String): String;
var
  Loop: Integer;

begin

  Result := '';
  Loop := SeekSL(FHeader, cLabel+':');

  if Loop >= 0 then
    Result := LabelValue(FHeader[Loop]);
end;

// Return de value of a parameter of a value from the header

function TMailPart.GetLabelParamValue(cLabel, Param: String): String;
var
  Loop: Integer;

begin

  Result := '';
  Loop := SeekSL(FHeader, cLabel+':');

  if Loop >= 0 then
    Result := TrimSpace(LabelParamValue(FHeader[Loop], Param));
end;

// Set the value of a label

procedure TMailPart.SetLabelValue(cLabel, cValue: String);
var
  Loop: Integer;

begin

  Loop := SeekSL(FHeader, cLabel+':');

  if cValue <> '' then
  begin

    if Loop < 0 then
    begin

      FHeader.Add(cLabel+': ');
      Loop := FHeader.Count-1;
    end;

    FHeader[Loop] := WriteLabelValue(FHeader[Loop], cValue);
  end
  else
  begin

    if Loop >= 0 then
    begin

      FHeader.Delete(Loop);
    end;
  end;
end;

// Set the value of a label parameter

procedure TMailPart.SetLabelParamValue(cLabel, cParam, cValue: String);
var
  Loop: Integer;

begin

  Loop := SeekSL(FHeader, cLabel+':');

  if Loop < 0 then
  begin

    FHeader.Add(cLabel+': ');
    Loop := FHeader.Count-1;
  end;

  FHeader[Loop] := WriteLabelParamValue(FHeader[Loop], cParam, cValue);
end;

// Look for a label in the header

function TMailPart.LabelExists(cLabel: String): Boolean;
begin

  Result := SeekSL(FHeader, cLabel+':') >= 0;
end;

// Look for a parameter in a label in the header

function TMailPart.LabelParamExists(cLabel, Param: String): Boolean;
var
  Loop: Integer;

begin

  Result := False;
  Loop := SeekSL(FHeader, cLabel+':');

  if Loop >= 0 then
    Result := TrimSpace(LabelParamValue(FHeader[Loop], Param)) <> '';
end;

// Divide header and body; normalize header;

procedure TMailPart.Fill(Data: PChar; HasHeader: Boolean);
const
  CRLF: array[0..2] of Char = (#13, #10, #0);

var
  Loop: Integer;
  BoundStart: array[0..99] of Char;
  BoundEnd: array[0..99] of Char;
  InBound: Boolean;
  IsBoundStart: Boolean;
  IsBoundEnd: Boolean;
  BoundStartLen: Integer;
  BoundEndLen: Integer;
  PartText: PChar;
  DataEnd: Boolean;
  MultPart: Boolean;
  NoParts: Boolean;
  InUUCode: Boolean;
  UUFile, UUBound: String;
  Part: TMailPart;
  nPos: Integer;
  nLen: Integer;
  nTL: Integer;
  nSPos: Integer;
  Line: PChar;
  SChar: Char;

begin

  if FOwnerMessage = nil then
    Exception.Create('MailPart must be owned by a MailMessage');

  for Loop := 0 to FSubPartList.Count-1 do
    FSubPartList.Items[Loop].Destroy;

  FHeader.Clear;
  FBody.Clear;
  FDecoded.Clear;
  FSubPartList.Clear;
  FOwnerMessage.FNeedRebuild := True;

  nPos := -1;
  DataEnd := False;
  nTL := StrLen(Data);
  nSPos := nTL+1;

  if (Self is TMailMessage) and Assigned(FOwnerMessage.FOnProgress) then
  begin

    FOwnerMessage.FOnProgress(Self, nTL, 0);
//    Process;
//    Application.ProcessMessages;
  end;

  if HasHeader then
  begin

    // Get Header

    DataLinePChar(Data, nTL, nPos, nLen, Line, DataEnd);

    while not DataEnd do
    begin

      if nLen = 0 then
      begin

        Break;
      end
      else
      begin

        if (Line[0] in [#9, #32]) and (FHeader.Count > 0) then
        begin

          FHeader[FHeader.Count-1] := FHeader[FHeader.Count-1] + #32 + String(PChar(@Line[1]));
        end
        else
        begin

          FHeader.Add(String(Line));
        end;
      end;

      DataLinePChar(Data, nTL, nPos, nLen, Line, DataEnd);

      if (Self is TMailMessage) and Assigned(FOwnerMessage.FOnProgress) then
      begin

        FOwnerMessage.FOnProgress(Self, nTL, nPos+1);
//        Application.ProcessMessages;
      end;
    end;

    for Loop := 0 to FHeader.Count-1 do
      FHeader[Loop] := NormalizeLabel(FHeader[Loop]);
  end;

  MultPart := Copy(GetLabelValue('Content-Type'), 1, 10) = 'multipart/';
  InBound := False;
  IsBoundStart := False;
  IsBoundEnd := False;
  UUBound := '';

  if MultPart then
  begin

    StrPCopy(BoundStart, '--'+GetLabelParamValue('Content-Type', 'boundary'));
    StrPCopy(BoundEnd, '--'+GetLabelParamValue('Content-Type', 'boundary')+'--');
    BoundStartLen := StrLen(BoundStart);
    BoundEndLen := StrLen(BoundEnd);
    NoParts := False;
  end
  else
  begin

    if LabelExists('Content-Type') then
    begin

      NoParts := True;
      BoundStartLen := 0;
      BoundEndLen := 0;
    end
    else
    begin

      StrPCopy(BoundStart, 'begin 666 ');
      StrPCopy(BoundEnd, 'end');
      BoundStartLen := StrLen(BoundStart);
      BoundEndLen := StrLen(BoundEnd);
      NoParts := False;
    end;
  end;

  PartText := nil;

  // Get Body

  DataLinePChar(Data, nTL, nPos, nLen, Line, DataEnd);

  while (not DataEnd) and (not InBound) do
  begin

    if (not NoParts) and (((Line[0] = '-') and (Line[1] = '-')) or ((Line[0] = 'b') and (Line[1] = 'e'))) then
    begin

      IsBoundStart := StrLComp(Line, BoundStart, BoundStartLen) = 0;
    end;

    if NoParts or (not IsBoundStart) then
    begin

      if PartText = nil then
      begin

        PartText := Line;
        nSPos := nPos;
      end;

      DataLinePChar(Data, nTL, nPos, nLen, Line, DataEnd);

      if (Self is TMailMessage) and Assigned(FOwnerMessage.FOnProgress) then
      begin

        FOwnerMessage.FOnProgress(Self, nTL, nPos+1);
//        Application.ProcessMessages;
      end;
    end
    else
    begin

      InBound := True;
    end;
  end;

  if nPos > nSPos then
  begin

    SChar := Data[nPos];
    Data[nPos] := #0;
    FBody.Write(PartText[0], nPos-nSPos);
    Data[nPos] := SChar;
  end;

  if not NoParts then
  begin

    PartText := nil;

    if MultPart then
    begin

      // Get Mime parts

      while not DataEnd do
      begin

        if IsBoundStart or IsBoundEnd then
        begin

          if (PartText <> nil) and (PartText[0] <> #0) then
          begin

            Part := TMailPart.Create(Self);
            Part.FOwnerPart := Self;
            Part.FOwnerMessage := Self.FOwnerMessage;

            SChar := Data[nPos-2];
            Data[nPos-2] := #0;
            Part.Fill(PartText, True);
            Data[nPos-2] := SChar;

            Part.FBoundary := GetLabelParamValue('Content-Type', 'boundary');
            FSubPartList.Add(Part);
            PartText := nil;
          end;

          if IsBoundEnd then
          begin

            Break;
          end;

          IsBoundStart := False;
          IsBoundEnd := False;
        end
        else
        begin

          if PartText = nil then
          begin

            PartText := Line;
          end;
        end;

        DataLinePChar(Data, nTL, nPos, nLen, Line, DataEnd);

        if (Self is TMailMessage) and Assigned(FOwnerMessage.FOnProgress) then
        begin

          FOwnerMessage.FOnProgress(Self, nTL, nPos+1);
//          Application.ProcessMessages;
        end;

        if not DataEnd then
        begin

          if (Line[0] = '-') and (Line[1] = '-') then
          begin

            IsBoundStart := StrLComp(Line, BoundStart, BoundStartLen) = 0;

            if not IsBoundStart then
            begin

              IsBoundEnd := StrLComp(Line, BoundEnd, BoundEndLen) = 0;
            end;
          end;
        end;
      end;
    end
    else
    begin

      // Get UUCode parts

      InUUCode := IsBoundStart;

      while not DataEnd do
      begin

        if IsBoundStart then
        begin

          if UUBound = '' then
          begin

            GetMem(PartText, FBody.Size+1);
            UUBound := GenerateBoundary;
            StrLCopy(PartText, FBody.Memory, FBody.Size);
            PartText[FBody.Size] := #0;

            Part := TMailPart.Create(Self);
            Part.FOwnerPart := Self;
            Part.FOwnerMessage := Self.FOwnerMessage;
            Part.Fill(PChar(EncodeQuotedPrintable(String(PartText), False)), False);
            Part.FBoundary := UUBound;
            Part.SetLabelValue('Content-Type', 'text/plain');
            Part.SetLabelParamValue('Content-Type', 'charset', '"'+FOwnerMessage.FCharset+'"');
            Part.SetLabelValue('Content-Transfer-Encoding', 'quoted-printable');

            FSubPartList.Add(Part);
            SetLabelValue('Content-Type', '');
            SetLabelValue('Content-Type', 'multipart/mixed');
            SetLabelParamValue('Content-Type', 'boundary', '"'+UUBound+'"');

            FreeMem(PartText);
          end;

          PartText := nil;
          IsBoundStart := False;
          UUFile := TrimSpace(Copy(String(Line), 11, 999));
        end
        else
        begin

          if IsBoundEnd then
          begin

            Part := TMailPart.Create(Self);
            Part.FOwnerPart := Self;
            Part.FOwnerMessage := Self.FOwnerMessage;

            SChar := Data[nPos-2];
            Data[nPos-2] := #0;
            DecodeUUCODE(PartText, Part.FDecoded);
            Data[nPos-2] := SChar;

            Part.EncodeBinary;
            Part.FBoundary := UUBound;
            Part.SetLabelValue('Content-Type', GetMimeType(UUFile));
            Part.SetLabelValue('Content-Transfer-Encoding', 'base64');
            Part.SetLabelValue('Content-Disposition', 'attachment');
            Part.SetLabelParamValue('Content-Type', 'name', '"'+UUFile+'"');
            Part.SetLabelParamValue('Content-Disposition', 'filename', '"'+UUFile+'"');

            FSubPartList.Add(Part);
            PartText := nil;
            IsBoundEnd := False;
          end
          else
          begin

            if PartText = nil then
            begin

              PartText := Line;
            end;
          end;
        end;

        DataLinePChar(Data, nTL, nPos, nLen, Line, DataEnd);

        if (Self is TMailMessage) and Assigned(FOwnerMessage.FOnProgress) then
        begin

          FOwnerMessage.FOnProgress(Self, nTL, nPos+1);
//          Application.ProcessMessages;
        end;

        if not DataEnd then
        begin

          if (Line[0] = 'b') and (Line[1] = 'e') then
          begin

            IsBoundStart := StrLComp(Line, BoundStart, BoundStartLen) = 0;
            InUUCode := True;
          end;

          if (not IsBoundStart) and InUUCode then
          begin

            if (Line[0] = 'e') and (Line[1] = 'n') and (Line[2] = 'd') then
            begin

              IsBoundEnd := True;
              InUUCode := False;
            end;
          end;
        end;
      end;
    end;
  end;

  if Self = FOwnerMessage then
  begin

    if not LabelExists('Content-Type') then
    begin

      SetLabelValue('Content-Type', 'text/plain');
    end;

    FOwnerMessage.PutText('', nil, '');
    FOwnerMessage.GetAttachList;
  end;
end;

// Remove mailpart from its owner

procedure TMailPart.Remove;
begin

  FOwnerPart.FSubPartList.Delete(FOwnerPart.FSubPartList.IndexOf(Self));
  FOwnerMessage.FNeedRebuild := True;
  Free;
end;

// Get file name of attachment

function TMailPart.GetFileName: String;
const
  InvChars: String = '<>?*:|"/\';

var
  Name: String;
  Loop: Integer;

begin

  Name := '';

  if LabelParamExists('Content-Type', 'name') then
  begin

    Name := GetLabelParamValue('Content-Type', 'name');
  end
  else
  begin

    if LabelParamExists('Content-Disposition', 'filename') then
    begin

      Name := GetLabelParamValue('Content-Disposition', 'filename');
    end
    else
    begin

      if LabelExists('Content-ID') then
      begin

        Name := GetLabelValue('Content-ID');
      end
      else
      begin

        if LabelExists('Content-Type') then
        begin

          Name := GetLabelValue('Content-Type')+GetMimeExtension(GetLabelValue('Content-Type'));
        end
        else
        begin

          Name := 'Unknow';
        end;
      end;
    end;
  end;

  Name := DecodeLine7Bit(Name);

  if Pos('.', Name) = 0 then
    Name := Name + GetMimeExtension(GetLabelValue('Content-Type'));

  Result := '';

  for Loop := 1 to Length(Name) do
    if Pos(Name[Loop], InvChars) = 0 then
      Result := Result + Name[Loop];
end;

// Get file name of attachment

function TMailPart.GetAttachInfo: String;
begin

  Result := GetLabelValue('Content-Type');
end;

// Write the content-type label

procedure TMailPart.SetAttachInfo(AttachInfo: String);
var
  Line: Integer;

begin

  Line := SeekSL(FHeader, 'Content-Type:');

  if Line < 0 then
  begin

    FHeader.Add('Content-Type: ');
    Line := FHeader.Count-1;
  end;

  FHeader[Line] := WriteLabelValue(FHeader[Line], AttachInfo);
end;

// Write the content-disposition label

procedure TMailPart.SetFileName(FileName: String);
var
  Line: Integer;

begin

  Line := SeekSL(FHeader, 'Content-Type:');

  if Line < 0 then
  begin

    FHeader.Add('Content-Type: ');
    Line := FHeader.Count-1;
  end;

  FHeader[Line] := WriteLabelValue(FHeader[Line], AttachInfo);
end;

// Decode mail part

function TMailPart.Decode : Boolean;
var
  Content: String;
  Encoding: String;
  Data: String;
  DecoLine: String;
  Buffer: PChar;
  Size: Integer;
  nPos: Integer;

begin

  Result := True;

  if FBody.Size = 0 then Exit;

  Content := GetLabelValue('Content-Type');
  Encoding := GetLabelValue('Content-Transfer-Encoding');

  FDecoded.Clear;

  if (Encoding = 'quoted-printable') or (Encoding = '7bit') then
  begin

    GetMem(Buffer, FBody.Size+1);
    StrLCopy(Buffer, FBody.Memory, FBody.Size);
    Buffer[FBody.Size] := #0;
    DecoLine := DecodeQuotedPrintable(Buffer);
    FreeMem(Buffer);

    GetMem(Buffer, Length(DecoLine)+1);
    StrPCopy(Buffer, DecoLine);
    FDecoded.Write(Buffer^, Length(DecoLine));
    FreeMem(Buffer);
  end
  else
  begin

    if Encoding = 'base64' then
    begin

      nPos := 1;

      SetLength(Data, FBody.Size);
      FBody.Position := 0;
      FBody.ReadBuffer(Data[1], FBody.Size);

      while nPos >= 0 do
      begin

        DataLine(Data, DecoLine, nPos);

        GetMem(Buffer, 132);
        Size := DecodeLineBASE64(TrimSpace(DecoLine), Buffer);

        if Size > 0 then
          FDecoded.Write(Buffer^, Size);

        FreeMem(Buffer);
      end;
    end
    else
    begin

      if Encoding = 'uucode' then
      begin

        nPos := 1;

        SetLength(Data, FBody.Size);
        FBody.Position := 0;
        FBody.ReadBuffer(Data[1], FBody.Size);

        while nPos >= 0 do
        begin

          DataLine(Data, DecoLine, nPos);

          GetMem(Buffer, 80);
          Size := DecodeLineUUCODE(TrimSpace(DecoLine), Buffer);
          FDecoded.Write(Buffer^, Size);
          FreeMem(Buffer);
        end;

        EncodeBinary; // Convert to base64
      end
      else
      begin

        if Encoding = '8bit' then
        begin

          FDecoded.LoadFromStream(FBody);
        end
        else
        begin

          Buffer := '(unknow encoding)';
          FDecoded.Write(Buffer^, StrLen(Buffer));
          Result := False;
        end;
      end;
    end;
  end;
end;

// Encode mail part in base64

procedure TMailPart.EncodeBinary;
begin

  EncodeBASE64(FBody, FDecoded);
  SetLabelValue('Content-Transfer-Encoding', 'base64');
end;

procedure TMailPart.Process;
begin
  if assigned(FOnProcess) then
    FOnProcess(Self)
  else
    Application.ProcessMessages;
end;

// Encode mail part in quoted-printable

procedure TMailPart.EncodeText;
var
  Buffer: String;
  Encoded: String;
begin

  SetLength(Buffer, FDecoded.Size);
  FDecoded.Position := 0;
  FDecoded.ReadBuffer(Buffer[1], FDecoded.Size);

  Encoded := EncodeQuotedPrintable(Buffer, False);
  FBody.Clear;
  FBody.Write(Encoded[1], Length(Encoded));
  SetLabelValue('Content-Transfer-Encoding', 'quoted-printable');
end;

{ TMailPartList ============================================================== }

// Retrieve an item from the list

function TMailPartList.Get(const Index: Integer): TMailPart;
begin

	Result := inherited Items[Index];
end;

// Finalize MailPartList

destructor TMailPartList.Destroy;
begin

  inherited Destroy;
end;

{ TMailMessage =============================================================== }

// Initialize MailMessage

constructor TMailMessage.Create(AOwner: TComponent);
begin

  FAttachList := TMailPartList.Create;
  FTextPlain := TStringList.Create;
  FTextHTML := TStringList.Create;
  FTextRTF := TStringList.Create;
  FTextPart := nil;
  FTextPlainPart := nil;
  FTextHTMLPart := nil;
  FTextRTFPart := nil;
  FNeedRebuild := False;
  FCharset := 'iso-8859-1';
  FNameCount := 0;

  inherited Create(AOwner);

  FOwnerMessage := Self;
end;

// Finalize MailMessage

destructor TMailMessage.Destroy;
begin

  FAttachList.Free;
  FTextPlain.Free;
  FTextHTML.Free;
  FTextRTF.Free;

  inherited Destroy;
end;

// Get a dest. name from a field

function TMailMessage.GetDestName(Field: String; const Index: Integer): String;
var
  Dests: String;
  Loop: Integer;
  Count: Integer;
  Quote: Boolean;
  Name: String;

begin

  Dests := TrimSpace(GetLabelValue(Field));
  Count := 0;
  Name := '';
  Quote := False;

  for Loop := 1 to Length(Dests) do
  begin

    if Dests[Loop] = '"' then
    begin

      Quote := not Quote;
    end
    else
    begin

      if (not Quote) and (Dests[Loop] in [',', ';']) then Inc(Count);

      if Count > Index then
      begin

        Name := '';
        Break;
      end;

      if Count = Index then
      begin

        if (Dests[Loop] = '<') and (not Quote) then
        begin

          Break;
        end
        else
        begin

          if Quote or (not (Dests[Loop] in [',', ';'])) then
            Name := Name + Dests[Loop];
        end;
      end;
    end;

    if Loop = Length(Dests) then Name := '';
  end;

  Result := DecodeLine7Bit(TrimSpace(Name));
end;

// Get a dest. address from a field

function TMailMessage.GetDestAddress(Field: String; const Index: Integer): String;
var
  Dests: String;
  Loop: Integer;
  Count: Integer;
  Quote: Boolean;
  Address: String;

begin

  Dests := TrimSpace(GetLabelValue(Field));
  Count := 0;
  Address := '';
  Quote := False;

  for Loop := 1 to Length(Dests) do
  begin

    if Dests[Loop] = '"' then
    begin

      Quote := not Quote;
    end
    else
    begin

      if (not Quote) and (Dests[Loop] in [',', ';']) then Inc(Count);

      if Count > Index then Break;

      if Count = Index then
      begin

        if (not Quote) and (not (Dests[Loop] in [',', ';', '<', '>', #32])) then
          Address := Address + Dests[Loop];

        if (Dests[Loop] = '<') and (not Quote) then
        begin

          Address := '';
        end;

        if (Dests[Loop] = '>') and (not Quote) then
        begin

          Break;
        end;
      end;
    end;
  end;

  Result := TrimSpace(Address);
end;

// Get a dest. count from a field

function TMailMessage.GetDestCount(Field: String): Integer;
var
  Dests: String;
  Loop: Integer;
  Quote: Boolean;

begin

  Dests := TrimSpace(GetLabelValue(Field));
  Result := 0;
  Quote := False;

  for Loop := 1 to Length(Dests) do
  begin

    if Result = 0 then Result := 1;

    if Dests[Loop] = '"' then
    begin

      Quote := not Quote;
    end
    else
    begin

      if (not Quote) and (Dests[Loop] in [',', ';']) then
        Inc(Result);
    end
  end;
end;

// Get a To: name

function TMailMessage.GetToName(const Index: Integer): String;
begin

  Result := GetDestName('To', Index);
end;

// Get a To: address

function TMailMessage.GetToAddress(const Index: Integer): String;
begin

  Result := GetDestAddress('To', Index);
end;

// Get To: count

function TMailMessage.GetToCount: Integer;
begin

  Result := GetDestCount('To');
end;

// Get a Cc: name

function TMailMessage.GetCcName(const Index: Integer): String;
begin

  Result := GetDestName('Cc', Index);
end;

// Get a Cc: address

function TMailMessage.GetCcAddress(const Index: Integer): String;
begin

  Result := GetDestAddress('Cc', Index);
end;

// Get Cc: count

function TMailMessage.GetCcCount: Integer;
begin

  Result := GetDestCount('Cc');
end;

// Get a Bcc: name

function TMailMessage.GetBccName(const Index: Integer): String;
begin

  Result := GetDestName('Bcc', Index);
end;

// Get a Bcc: address

function TMailMessage.GetBccAddress(const Index: Integer): String;
begin

  Result := GetDestAddress('Bcc', Index);
end;

// Get Bcc: count

function TMailMessage.GetBccCount: Integer;
begin

  Result := GetDestCount('Bcc');
end;

// Add a name/address to a field

procedure TMailMessage.AddDest(Field, Name, Address: String);
var
  Line: Integer;
  Dests: String;

begin

  Line := SeekSL(FHeader, Field + ':');

  if Line < 0 then
  begin

    FHeader.Add(Field + ': "' + EncodeLine7Bit(Name, FCharset) + '" <' + Address + '>');
  end
  else
  begin

    Dests := TrimSpace(FHeader[Line]);

    if Dests[Length(Dests)] <> ':' then
      Dests := Dests + ',';

    Dests := Dests + ' "' + EncodeLine7Bit(Name, FCharset) + '" <' + Address + '>';

    FHeader[Line] := Dests;
  end;
end;

// Add a name/address to To:

procedure TMailMessage.AddTo(Name, Address: String);
begin

  AddDest('To', Name, Address);
end;

// Add a name/address to Cc:

procedure TMailMessage.AddCc(Name, Address: String);
begin

  AddDest('Cc', Name, Address);
end;

// Add a name/address to Bcc:

procedure TMailMessage.AddBcc(Name, Address: String);
begin

  AddDest('Bcc', Name, Address);
end;

// Clear the To: label

procedure TMailMessage.ClearTo;
var
  Line: Integer;

begin

  Line := SeekSL(FHeader, 'To:');

  if Line >= 0 then FHeader.Delete{Line}(Line);
end;

// Clear the Cc: label

procedure TMailMessage.ClearCc;
var
  Line: Integer;

begin

  Line := SeekSL(FHeader, 'Cc:');

  if Line >= 0 then FHeader.Delete{Line}(Line);
end;

// Clear the Bcc: label

procedure TMailMessage.ClearBcc;
var
  Line: Integer;

begin

  Line := 0;

  while Line >= 0 do
  begin

    Line := SeekSL(FHeader, 'Bcc:');

    if Line >= 0 then FHeader.Delete(Line);
  end;
end;

// Get the From: name

function TMailMessage.GetFromName: String;
begin

  Result := GetDestName('From', 0);
end;

// Get the From: address

function TMailMessage.GetFromAddress: String;
begin

  Result := GetDestAddress('From', 0);
end;

// Get the Reply-To: name

function TMailMessage.GetReplyToName: String;
begin

  Result := GetDestName('Reply-To', 0);
end;

// Get the Reply-To: address

function TMailMessage.GetReplyToAddress: String;
begin

  Result := GetDestAddress('Reply-To', 0);
end;

// Set the From: name/address

procedure TMailMessage.SetFrom(Name, Address: String);
begin

  SetLabelValue('From', '"' + EncodeLine7Bit(Name, FCharset) + '" <' + Address + '>');
end;

// Set the Reply-To: name/address

procedure TMailMessage.SetReplyTo(Name, Address: String);
begin

  SetLabelValue('Reply-To', '"' + EncodeLine7Bit(Name, FCharset) + '" <' + Address + '>');
end;

// Get the subject

function TMailMessage.GetSubject: String;
begin

  Result := DecodeLine7Bit(GetLabelValue('Subject'));
end;

// Set the subject

procedure TMailMessage.SetSubject(Subject: String);
begin

  SetLabelValue('Subject', EncodeLine7Bit(Subject, FCharset));
end;

// Get the date in TDateTime format

function TMailMessage.GetDate: TDateTime;
const
  Months: String = 'Jan,Feb,Mar,Apr,May,Jun,Jul,Ago,Sep,Oct,Nov,Dec,';

var
  DateStr: String;
  Field, Loop: Integer;
  Hour, Min, Sec, Year, Month, Day: Word;
  sHour, sMin, sSec, sYear, sMonth, sDay, sTZ: String;
  HTZM, MTZM: Word;
  STZM: Integer;
  TZM: Double;

begin

  DateStr := TrimSpace(GetLabelValue('Date'));
  sHour := '';
  sMin := '';
  sSec := '';
  sYear := '';
  sMonth := '';
  sDay := '';
  sTZ := '';

  if DateStr <> '' then
  begin

    if DateStr[1] in ['0'..'9'] then
      Field := 1
    else
      Field := 0;

    for Loop := 1 to Length(DateStr) do
    begin

      if DateStr[Loop] in [' ', ':'] then
      begin

        Inc(Field);
      end
      else
      begin

        case Field of

          1: sDay := sDay + DateStr[Loop];
          2: sMonth := sMonth + DateStr[Loop];
          3: sYear := sYear + DateStr[Loop];
          4: sHour := sHour + DateStr[Loop];
          5: sMin := sMin + DateStr[Loop];
          6: sSec := sSec + DateStr[Loop];
          7: sTZ := sTZ + DateStr[Loop];
        end;
      end;
    end;

    Hour := StrToIntDef(sHour, 0);
    Min := StrToIntDef(sMin, 0);
    Sec := StrToIntDef(sSec, 0);
    Year := StrToIntDef(syear, 0);
    Month := (Pos(sMonth, Months)-1) div 4 + 1;
    Day := StrToIntDef(sDay, 0);

    if sTZ = 'GMT' then
    begin

      STZM := 1;
      HTZM := 0;
      MTZM := 0;
    end
    else
    begin

      STZM := StrToIntDef(Copy(sTZ, 1, 1)+'1', 1);
      HTZM := StrToIntDef(Copy(sTZ, 2, 2), 0);
      MTZM := StrToIntDef(Copy(sTZ, 4, 2), 0);
    end;

    TZM := EncodeTime(HTZM, MTZM, 0, 0)*STZM;

    Result := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Min, Sec, 0) + TZM - GetTimeZoneBias;
  end
  else
  begin

    Result := Now;
  end;
end;

// Set the date in RFC822 format

procedure TMailMessage.SetDate(Date: TDateTime);
const
  Months: String = 'Jan,Feb,Mar,Apr,May,Jun,Jul,Ago,Sep,Oct,Nov,Dec,';
  Weeks: String = 'Sun,Mon,Tue,Wed,Thu,Fri,Sat,';

var
  TZH: Double;
  DateStr: String;
  TZStr: String;
  Day, Month, Year: Word;

begin

  TZH := GetTimeZoneBias;
  DecodeDate(Date, Year, Month, Day);

  if TZH < 0 then
  begin

    TZStr := '-'+FormatDateTime('hhmm', Abs(TZH));
  end
  else
  begin

    if TZH = 0 then
    begin

      TZStr := 'GMT'
    end
    else
    begin

      TZStr := '+'+FormatDateTime('hhmm', Abs(TZH));
    end;
  end;

  DateStr := Copy(Weeks, (DayOfWeek(Date)-1)*4+1, 3)+',';
  DateStr := DateStr + FormatDateTime(' dd ', Date);
  DateStr := DateStr + Copy(Months, (Month-1)*4+1, 3);
  DateStr := DateStr + FormatDateTime(' yyyy hh:nn:ss ', Date) + TZStr;

  SetLabelValue('Date', DateStr);
end;

// Get message id

function TMailMessage.GetMessageId: String;
begin

  Result := GetLabelValue('Message-ID');
end;

// Set a unique message id (the parameter is just the host)

procedure TMailMessage.SetMessageId(MessageId: String);
var
  IDStr: String;
begin

  IDStr := '<'+FormatDateTime('yyyymmddhhnnss', Now)+'.'+TrimSpace(Format('%8x', [Random($FFFFFFFF)]))+'.'+TrimSpace(Format('%8x', [Random($FFFFFFFF)]))+'@'+MessageId+'>';

  SetLabelValue('Message-ID', IDStr);
end;

// Searches for attached files and determines AttachList, TextPlain, TextHTML and TextRTF.

procedure TMailMessage.GetAttachList;
var
  Text: PChar;

  procedure DecodeRec(MPL: TMailPartList);
  var
    Loop: Integer;
    Buffer: PChar;
    Ext: String;
    IsText: Boolean;

  begin

    for Loop := 0 to MPL.Count-1 do
    begin

      if (FTextPart = nil) and (MPL[Loop].GetAttachInfo = 'multipart/alternative') then
      begin

        FTextPart := MPL[Loop];
      end;

      IsText := False;

      if (FTextPlainPart = nil) and (MPL[Loop].GetAttachInfo = 'text/plain') then
      begin

        IsText := True;

        FTextPlainPart := MPL[Loop];

        if MPL[Loop].Decode then
        begin

          GetMem(Buffer, MPL[Loop].FDecoded.Size+1);
          StrLCopy(Buffer, MPL[Loop].FDecoded.Memory, MPL[Loop].FDecoded.Size);
          Buffer[MPL[Loop].FDecoded.Size] := #0;
          FTextPlain.SetText(Buffer);
          FreeMem(Buffer);
        end
        else
        begin

          GetMem(Text, MPL[Loop].FBody.Size+1);
          StrLCopy(Text, MPL[Loop].FBody.Memory, MPL[Loop].FBody.Size);
          Text[MPL[Loop].FBody.Size] := #0;
          FTextPlain.SetText(Text);
          FreeMem(Text);
        end;
      end;

      if (FTextHTMLPart = nil) and (MPL[Loop].GetAttachInfo = 'text/html') then
      begin

        IsText := True;

        FTextHTMLPart := MPL[Loop];

        if MPL[Loop].Decode then
        begin

          GetMem(Buffer, MPL[Loop].FDecoded.Size+1);
          StrLCopy(Buffer, MPL[Loop].FDecoded.Memory, MPL[Loop].FDecoded.Size);
          Buffer[MPL[Loop].FDecoded.Size] := #0;
          FTextHTML.SetText(Buffer);
          FreeMem(Buffer);
        end
        else
        begin

          GetMem(Text, MPL[Loop].FBody.Size+1);
          StrLCopy(Text, MPL[Loop].FBody.Memory, MPL[Loop].FBody.Size);
          Text[MPL[Loop].FBody.Size] := #0;
          FTextHTML.SetText(Text);
          FreeMem(Text);
        end;
      end;

      if (FTextRTFPart = nil) and ((MPL[Loop].GetAttachInfo = 'text/richtext') or (MPL[Loop].GetAttachInfo = 'text/enriched')) then
      begin

        IsText := True;

        FTextRTFPart := MPL[Loop];

        if MPL[Loop].Decode then
        begin

          GetMem(Buffer, MPL[Loop].FDecoded.Size+1);
          StrLCopy(Buffer, MPL[Loop].FDecoded.Memory, MPL[Loop].FDecoded.Size);
          Buffer[MPL[Loop].FDecoded.Size] := #0;
          FTextRTF.SetText(Buffer);
          FreeMem(Buffer);
        end
        else
        begin

          GetMem(Text, MPL[Loop].FBody.Size+1);
          StrLCopy(Text, MPL[Loop].FBody.Memory, MPL[Loop].FBody.Size);
          Text[MPL[Loop].FBody.Size] := #0;
          FTextRTF.SetText(Text);
          FreeMem(Text);
        end;
      end;

      if (not IsText) and (Copy(MPL[Loop].GetAttachInfo, 1, 10) <> 'multipart/') then
      begin

        if MPL[Loop].GetLabelValue('Content-Type') = '' then
        begin

          MPL[Loop].SetLabelValue('Content-Type', GetMimeType('?'));
        end;

        if (MPL[Loop].GetLabelParamValue('Content-Type', 'name') = '') and
           (MPL[Loop].GetLabelValue('Content-ID') = '') and
           (MPL[Loop].GetLabelParamValue('Content-Disposition', 'filename') = '') then
        begin

          Ext := GetMimeExtension(MPL[Loop].GetLabelValue('Content-Type'));

          MPL[Loop].SetLabelParamValue('Content-Type', 'name', '"file_'+IntToStr(FNameCount)+Ext+'"');
          Inc(FNameCount);
        end;

        if MPL[Loop].GetLabelValue('Content-Transfer-Encoding') = '' then
        begin

          MPL[Loop].SetLabelValue('Content-Transfer-Encoding', '8bit');
        end;

        FAttachList.Add(MPL[Loop]);
      end;

      DecodeRec(MPL[Loop].FSubPartList);
    end;
  end;

begin

  FAttachList.Clear;
  FTextPart := nil;
  FTextPlainPart := nil;
  FTextHTMLPart := nil;
  FTextRTFPart := nil;
  FTextPlain.Clear;
  FTextHTML.Clear;
  FTextRTF.Clear;
  FNameCount := 0;

  DecodeRec(FSubPartList);

  if Decode then
  begin

    GetMem(Text, FDecoded.Size+1);
    StrLCopy(Text, FDecoded.Memory, FDecoded.Size);
    Text[FBody.Size] := #0;
  end
  else
  begin

    GetMem(Text, FBody.Size+1);
    StrLCopy(Text, FBody.Memory, FBody.Size);
    Text[FBody.Size] := #0;
  end;

  if (FTextPlain.Count = 0) and (GetLabelValue('Content-Type') = 'text/plain') then
    FTextPlain.SetText(Text);

  if (FTextHTML.Count = 0) and (GetLabelValue('Content-Type') = 'text/html') then
    FTextHTML.SetText(Text);

  if (FTextRTF.Count = 0) and ((GetLabelValue('Conetnt-Type') = 'text/richtext') or (GetLabelValue('Conetnt-Type') = 'text/enriched')) then
    FTextRTF.SetText(Text);

  if (FTextPlain.Count = 0) and (not LabelExists('Content-Type')) then
    FTextPlain.SetText(Text);

  FreeMem(Text);
end;

// Create a mailpart and encode the file

procedure TMailMessage.AttachFile(FileName: String);
var
  Boundary: String;
  Part: TMailPart;
  Loop: Integer;

begin

  if (GetLabelValue('Content-Type') = 'multipart/alternative') and (FTextPart = nil) then
  begin

    Boundary := GenerateBoundary;
    FTextPart := TMailPart.Create(Self);
    FTextPart.FOwnerPart := Self;
    FTextPart.FOwnerMessage := Self.FOwnerMessage;
    FTextPart.FBoundary := GetLabelParamValue('Content-Type', 'boundary');
    FTextPart.SetLabelValue('Content-Type', '');
    FTextPart.SetLabelValue('Content-Type', 'multipart/alternative');
    FTextPart.SetLabelParamValue('Content-Type', 'boundary', '"'+Boundary+'"');
    FTextPart.SetLabelValue('Content-Transfer-Encoding', '8bit');

    for Loop := 0 to FSubPartList.Count do
    begin

      FTextPart.FSubPartList.Add(FSubPartList[Loop]);
    end;

    FSubPartList.Clear;
    FSubPartList.Add(FTextPart);
    SetLabelValue('Content-Type', '');
    SetLabelValue('Content-Type', 'multipart/mixed');
  end
  else
  begin

    if not LabelExists('Content-Type') then
    begin

      SetLabelValue('Content-Type', 'text/plain');
    end;

    PutText('', nil, '');
  end;

  Part := TMailPart.Create(Self);
  Part.FOwnerPart := Self;
  Part.FOwnerMessage := Self.FOwnerMessage;
  FSubPartList.Add(Part);

  Part.Decoded.LoadFromFile(FileName);
  Part.EncodeBinary;
  Part.FBoundary := GetLabelParamValue('Content-Type', 'boundary');
  Part.SetLabelValue('Content-Type', GetMimeType(FileName));
  Part.SetLabelParamValue('Content-Type', 'name', '"'+ExtractFileName(FileName)+'"');
  Part.SetLabelValue('Content-Disposition', 'attachment');
  Part.SetLabelParamValue('Content-Disposition', 'filename', '"'+ExtractFileName(FileName)+'"');
  Part.SetLabelValue('Content-ID', '<'+ExtractFileName(FileName)+'>');

  FNeedRebuild := True;
end;

// Rebuild body text according to the mailparts

procedure TMailMessage.RebuildBody;
var
  sLine: String;

  procedure RebuildBodyRec(MP: TMailPart);
  var
    Loop: Integer;
    Line: Integer;
    Data: String;
    nPos: Integer;

  begin

    for Loop := 0 to MP.SubPartList.Count-1 do
    begin

      sLine := #13#10;
      FBody.Write(sLine[1], Length(sLine));

      sLine :=  '--'+MP.SubPartList[Loop].FBoundary+#13#10;
      FBody.Write(sLine[1], Length(sLine));

      for Line := 0 to MP.SubPartList[Loop].FHeader.Count-1 do
      begin

        sLine := MP.SubPartList[Loop].FHeader[Line];

        if Length(sLine) > 0 then
        begin

          sLine := MP.SubPartList[Loop].FHeader[Line]+#13#10;
          FBody.Write(sLine[1], Length(sLine));
        end;
      end;

      sLine := #13#10;
      FBody.Write(sLine[1], Length(sLine));

      if MP.SubPartList[Loop].SubPartList.Count > 0 then
      begin

        RebuildBodyRec(MP.SubPartList[Loop]);
      end
      else
      begin

        SetLength(Data, MP.SubPartList[Loop].FBody.Size);

        if MP.SubPartList[Loop].FBody.Size > 0 then
        begin

          MP.SubPartList[Loop].FBody.Position := 0;
          MP.SubPartList[Loop].FBody.ReadBuffer(Data[1], MP.SubPartList[Loop].FBody.Size);

          nPos := 1;

          while nPos >= 0 do
          begin

            DataLine(Data, sLine, nPos);

            sLine := sLine;
            FBody.Write(sLine[1], Length(sLine));
          end;
        end;
      end;
    end;

    if MP.SubPartList.Count > 0 then
    begin

      sLine := #13#10;
      FBody.Write(sLine[1], Length(sLine));

      sLine := '--'+MP.SubPartList[0].FBoundary+'--'#13#10;
      FBody.Write(sLine[1], Length(sLine));
    end;
  end;

begin

  if SubPartList.Count > 0 then
  begin

    FBody.Clear;

    sLine := 'This is a multipart message in mime format.'#13#10;
    FBody.Write(sLine[1], Length(sLine));

    RebuildBodyRec(Self);
  end;

  FNeedRebuild := False;
end;

procedure TMailMessage.PutText(Text: String; Part: TMailPart; Content: String);
var
  Buffer: PChar;
  Boundary: String;
  Data: String;

begin

  if (SubPartList.Count = 0) and
     (Copy(GetLabelValue('Content-Type'), 1, 5) = 'text/') and
     (GetLabelValue('Content-Type') <> Content) then
  begin

    SetLength(Data, FBody.Size);

    if Length(Data) > 0 then
    begin

      FBody.Position := 0;
      FBody.ReadBuffer(Data[1], FBody.Size);
    end
    else
    begin

      Data := #13#10;
    end;

    if GetLabelValue('Content-Type') = 'text/plain' then
      PutText(Data, FTextPlainPart, 'text/plain');

    if GetLabelValue('Content-Type') = 'text/html' then
      PutText(Data, FTextHTMLPart, 'text/html');

    if (GetLabelValue('Content-Type') = 'text/richtext') or (GetLabelValue('Content-Type') = 'text/enriched') then
      PutText(Data, FTextRTFPart, 'text/enriched');
  end
  else
  begin

    if Text <> '' then
    begin

      GetAttachList;
      FNeedRebuild := True;

      if Part <> nil then
      begin

        Buffer := PChar(Text);
        Part.Decoded.Clear;
        Part.Decoded.Write(Buffer^, Length(Text));
        Part.EncodeText;
      end
      else
      begin

        if FTextPart = nil then
        begin

          Boundary := GenerateBoundary;
          FTextPart := TMailPart.Create(Self);
          FTextPart.FOwnerPart := Self;
          FTextPart.FOwnerMessage := Self.FOwnerMessage;
          FTextPart.SetLabelValue('Content-Type', '');
          FTextPart.SetLabelValue('Content-Type', 'multipart/alternative');
          FTextPart.SetLabelParamValue('Content-Type', 'boundary', '"'+Boundary+'"');
          FTextPart.SetLabelValue('Content-Transfer-Encoding', '8bit');

          FSubPartList.Insert(0, FTextPart);

          Boundary := GenerateBoundary;
          SetLabelValue('Content-Type', '');
          SetLabelValue('Content-Type', 'multipart/mixed');
          SetLabelParamValue('Content-Type', 'boundary', '"'+Boundary+'"');
          FTextPart.FBoundary := Boundary;

          if FTextPlainPart <> nil then
          begin

            if FTextPlainPart.FOwnerPart = Self then
            begin

              FSubPartList.Delete(FSubPartList.IndexOf(FTextPlainPart));
              FTextPart.FSubPartList.Insert(0, FTextPlainPart);
              FTextPlainPart.FOwnerPart := FTextPart;
              FTextPlainPart.FBoundary := FTextPart.GetLabelParamValue('Content-Type', 'boundary');
            end;
          end;

          if FTextHTMLPart <> nil then
          begin

            if FTextHTMLPart.FOwnerPart = Self then
            begin

              FSubPartList.Delete(FSubPartList.IndexOf(FTextHTMLPart));
              FTextPart.FSubPartList.Insert(0, FTextHTMLPart);
              FTextHTMLPart.FOwnerPart := FTextPart;
              FTextHTMLPart.FBoundary := FTextPart.GetLabelParamValue('Content-Type', 'boundary');
            end;
          end;

          if FTextRTFPart <> nil then
          begin

            if FTextRTFPart.FOwnerPart = Self then
            begin

              FSubPartList.Delete(FSubPartList.IndexOf(FTextRTFPart));
              FTextPart.FSubPartList.Insert(0, FTextRTFPart);
              FTextRTFPart.FOwnerPart := FTextPart;
              FTextRTFPart.FBoundary := FTextPart.GetLabelParamValue('Content-Type', 'boundary');
            end;
          end;
        end;

        Part := TMailPart.Create(Self);
        Part.FOwnerPart := FTextPart;
        Part.FOwnerMessage := Self.FOwnerMessage;
        Buffer := PChar(Text);
        Part.Decoded.Clear;
        Part.Decoded.Write(Buffer^, Length(Text));
        Part.SetLabelValue('Content-Type', Content);
        Part.SetLabelParamValue('Content-Type', 'charset', '"'+FOwnerMessage.FCharset+'"');
        Part.EncodeText;

        Part.FBoundary := FTextPart.GetLabelParamValue('Content-Type', 'boundary');
        FTextPart.SubPartList.Add(Part);
      end;
    end;
  end;
end;

// Replace or create a mailpart for text/plain

procedure TMailMessage.SetTextPlain(Text: TStrings);
begin

  PutText(Text.Text, FTextPlainPart, 'text/plain');
end;

// Replace or create a mailpart for text/html

procedure TMailMessage.SetTextHTML(Text: TStrings);
begin

  PutText(Text.Text, FTextHTMLPart, 'text/html');
end;

// Replace or create a mailpart for text/html

procedure TMailMessage.SetTextRTF(Text: TStrings);
begin

  PutText(Text.Text, FTextRTFPart, 'text/enriched');
end;

// Remove text/plain mailpart

procedure TMailMessage.RemoveTextPlain;
begin

  if FTextPlainPart <> nil then
    FTextPlainPart.Remove;

  FTextPlainPart := nil;
end;

// Remove text/html mailpart

procedure TMailMessage.RemoveTextHTML;
begin

  if FTextHTMLPart <> nil then
    FTextHTMLPart.Remove;

  FTextHTMLPart := nil;
end;

// Remove text/enriched mailpart

procedure TMailMessage.RemoveTextRTF;
begin

  if FTextRTFPart <> nil then
    FTextRTFPart.Remove;

  FTextRTFPart := nil;
end;

// Empty data stored in the object

procedure TMailMessage.Reset;
var
  Loop: Integer;

begin

  for Loop := 0 to FSubPartList.Count-1 do
    FSubPartList.Items[Loop].Destroy;

  FHeader.Clear;
  FBody.Clear;
  FDecoded.Clear;
  FSubPartList.Clear;

  FAttachList.Clear;
  FTextPlain.Clear;
  FTextHTML.Clear;
  FTextRTF.Clear;
  FTextPart := nil;
  FTextPlainPart := nil;
  FTextHTMLPart := nil;
  FTextRTFPart := nil;
  FNeedRebuild := False;
  FNameCount := 0;
end;

{ TSocketTalk =================================================================== }

// Initialize TSocketTalk

constructor TSocketTalk.Create(AOwner: TComponent);
begin

  FClientSocket := TClientSocket.Create(Self);
  FClientSocket.ClientType := ctNonBlocking;
  FClientSocket.OnRead := SocketRead;
  FClientSocket.OnError := SocketError;
  FClientSocket.OnDisconnect := SocketDisconnect;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := Timer;

  FTimeOut := 60;
  FLastResponse := '';
  FExpectedEnd := '';
  FDataSize := 0;
  FPacketSize := 0;
  FTalkError := teNoError;

  inherited Create(AOwner);
end;

// Finalize TSocketTalk

destructor TSocketTalk.Destroy;
begin

  FClientSocket.Free;
  FTimer.Free;

  inherited Destroy;
end;

// Occurs when data is comming from the socket

procedure TSocketTalk.SocketRead(Sender: TObject; Socket: TCustomWinSocket);
var
  Buffer: String;

begin

	SetLength(Buffer, Socket.ReceiveLength);
	Socket.ReceiveBuf(Buffer[1], Length(Buffer));

  FLastResponse := FLastResponse + Buffer;
  FTalkError := teNoError;
  FTimer.Enabled := False;

  if Assigned(FOnReceiveData) then
  begin

    FOnReceiveData(Self, FSessionState, Buffer, FServerResult);
  end;

  if (FDataSize > 0) and Assigned(FOnProgress) then
  begin

    FOnProgress(Self.Owner, FDataSize, Length(FLastResponse));
  end;

  if (FExpectedEnd = '') or (Copy(FLastResponse, Length(FLastResponse)-Length(FExpectedEnd)+1, Length(FExpectedEnd)) = FExpectedEnd) then
  begin

    FTalkError := teNoError;
    FDataSize := 0;
    FExpectedEnd := '';
    FWaitingServer := False;

    if Assigned(FOnEndOfData) then
    begin

      FOnEndOfData(Self, FSessionState, FLastResponse, FServerResult);
    end;

    FSessionState := stNone;
  end
  else
  begin

    FTimer.Enabled := True;
  end;
end;

// Occurs when socket is disconnected

procedure TSocketTalk.SocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin

  if Assigned(FOnDisconnect) then
    FOnDisconnect(Self);

  FTimer.Enabled := False;
  FExpectedEnd := '';
  FDataSize := 0;
  FPacketSize := 0;
end;

// Occurs on socket error

procedure TSocketTalk.SocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin

  FTimer.Enabled := False;
  FTalkError := TTalkError(Ord(ErrorEvent));
  FDataSize := 0;
  FExpectedEnd := '';
  FWaitingServer := False;
  FServerResult := False;

  if Assigned(FOnSocketTalkError) then
  begin

    FOnSocketTalkError(Self, FSessionState, FTalkError);
  end;

  FSessionState := stNone;
  ErrorCode := 0;
end;

// Occurs on timeout

procedure TSocketTalk.Timer(Sender: TObject);
begin

  FTimer.Enabled := False;
  FTalkError := teTimeout;
  FDataSize := 0;
  FExpectedEnd := '';
  FWaitingServer := False;
  FServerResult := False;

  if Assigned(FOnSocketTalkError) then
  begin

    FOnSocketTalkError(Self, FSessionState, FTalkError);
  end;

  FSessionState := stNone;
end;

procedure TSocketTalk.Process;
begin
  if assigned(FOnProcess) then
    FOnProcess(Self);
  Application.ProcessMessages;
end;

// Cancel waiting for server response

procedure TSocketTalk.Cancel;
begin

  FTimer.Enabled := False;
  FTalkError := teNoError;
  FSessionState := stNone;
  FExpectedEnd := '';
  FDataSize := 0;
  FWaitingServer := False;
  FServerResult := False;
end;

// Inform that the data comming belongs

procedure TSocketTalk.ForceState(SessionState: TSessionState);
begin

  FExpectedEnd := '';
  FLastResponse := '';
  FTimer.Interval := FTimeOut * 1000;
  FTimer.Enabled := True;
  FDataSize := 0;
  FTalkError := teNoError;
  FSessionState := SessionState;
  FWaitingServer := True;
  FServerResult := False;
end;

// Send a command to server

procedure TSocketTalk.Talk(Buffer, EndStr: String; SessionState: TSessionState);
var
  nPos: Integer;
  nLen: Integer;

begin

  FExpectedEnd := EndStr;
  FSessionState := SessionState;
  FLastResponse := '';
  FTimer.Interval := FTimeOut * 1000;
  FTimer.Enabled := True;
  FTalkError := teNoError;
  FWaitingServer := True;
  FServerResult := False;
  nPos := 1;

  if (FPacketSize > 0) and (Length(Buffer) > FPacketSize) then
  begin

    if Assigned(OnProgress) then
      OnProgress(Self.Owner, Length(Buffer), 0);

    while nPos <= Length(Buffer) do
    begin

      Process;
//      Application.ProcessMessages;

      if (nPos+FPacketSize-1) > Length(Buffer) then
        nLen := Length(Buffer)-nPos+1
      else
        nLen := FPacketSize;

      FClientSocket.Socket.SendBuf(Buffer[nPos], nLen);

      nPos := nPos + nLen;

      if Assigned(OnProgress) then
        OnProgress(Self.Owner, Length(Buffer), nPos-1);
    end;
  end
  else
  begin

    FClientSocket.Socket.SendBuf(Buffer[1], Length(Buffer));
  end;

  FPacketSize := 0;
end;

// Wait for server response

procedure TSocketTalk.WaitServer;
begin

  while FWaitingServer and (not FServerResult) do
  begin

    Sleep(10);
    Process;
    Application.ProcessMessages;
  end;
end;

{ TPOP2000 ====================================================================== }

// Initialize TPOP2000

constructor TPOP2000.Create;
begin

  FSocketTalk := TSocketTalk.Create(Self);
  FSocketTalk.OnEndOfData := EndOfData;
  FSocketTalk.OnSocketTalkError := SocketTalkError;
  FSocketTalk.OnReceiveData := ReceiveData;
  FSocketTalk.OnDisconnect := SocketDisconnect;

  FHost := '';
  FPort := 110;
  FUserName := '';
  FPassword := '';
  FSessionMessageCount := -1;
  FSessionConnected := False;
  FSessionLogged := False;
  FMailMessage := nil;
  FProxyPort := 23;
  FProxyHost := '';
  FProxyUsage := False;
  FProxyString := '%h% %p%';

  SetLength(FSessionMessageSize, 0);

  inherited Create(AOwner);
end;

// Finalize TPOP2000

destructor TPOP2000.Destroy;
begin

  FSocketTalk.Free;

  SetLength(FSessionMessageSize, 0);

  inherited Destroy;
end;

// Set timeout

procedure TPOP2000.SetTimeOut(Value: Integer);
begin

  FSocketTalk.TimeOut := Value;
end;

// Get timeout

function TPOP2000.GetTimeOut: Integer;
begin

  Result := FSocketTalk.TimeOut;
end;

// Set OnProgress event

procedure TPOP2000.SetProgress(Value: TProgressEvent);
begin

  FSocketTalk.OnProgress := Value;
end;

// Get OnProgress event

function TPOP2000.GetProgress: TProgressEvent;
begin

  Result := FSocketTalk.OnProgress;
end;

// Get LastResponse

function TPOP2000.GetLastResponse: String;
begin

  Result := FSocketTalk.LastResponse;
end;

// When data from server ends

procedure TPOP2000.EndOfData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
begin

  case SessionState of

    stProxy: ServerResult := True;

    stConnect, stUser, stPass, stStat, stList, stRetr, stQuit:
    if Copy(Data, 1, 4) = '+OK ' then
      ServerResult := True;
  end;
end;

// On socket error

procedure TPOP2000.SocketTalkError(Sender: TObject; SessionState: TSessionState; TalkError: TTalkError);
begin

  FSocketTalk.Cancel;
end;

// On data received

procedure TPOP2000.ReceiveData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
begin

  if (Copy(Data, 1, 5) = '-ERR ') and (Copy(Data, Length(Data)-1, 2) = #13#10) then
  begin

    ServerResult := False;
    FSocketTalk.Cancel;
  end;
end;

// On socket disconnected

procedure TPOP2000.SocketDisconnect(Sender: TObject);
begin

  FSessionMessageCount := -1;
  FSessionConnected := False;
  FSessionLogged := False;

  SetLength(FSessionMessageSize, 0);
end;

// Connect socket

function TPOP2000.Connect: Boolean;
var
  Connect: String;

begin

  if FSessionConnected or FSocketTalk.ClientSocket.Active then
  begin

    Result := False;
    Exit;
  end;

  if Length(FHost) = 0 then
  begin

    Result := False;
    Exit;
  end;

  if not FProxyUsage then
  begin

    if not IsIPAddress(FHost) then
    begin

      FSocketTalk.ClientSocket.Host := FHost;
      FSocketTalk.ClientSocket.Address := '';
    end
    else
    begin

      FSocketTalk.ClientSocket.Host := '';
      FSocketTalk.ClientSocket.Address := FHost;
    end;

    FSocketTalk.ClientSocket.Port := FPort;
    FSocketTalk.ForceState(stConnect);
    FSocketTalk.ClientSocket.Open;
  end
  else
  begin

    Connect := FindReplace(FProxyString, '%h%', FHost);
    Connect := FindReplace(Connect, '%p%', IntToStr(FPort));
    Connect := FindReplace(Connect, '%u%', FUserName);

    if not IsIPAddress(FProxyHost) then
    begin

      FSocketTalk.ClientSocket.Host := FProxyHost;
      FSocketTalk.ClientSocket.Address := '';
    end
    else
    begin

      FSocketTalk.ClientSocket.Host := '';
      FSocketTalk.ClientSocket.Address := FProxyHost;
    end;

    FSocketTalk.ClientSocket.Port := FProxyPort;
    FSocketTalk.ForceState(stProxy);
    FSocketTalk.ClientSocket.Open;
    FSocketTalk.WaitServer;

    if FSocketTalk.ServerResult then
      FSocketTalk.Talk(Connect+#13#10, #13#10, stConnect);
  end;

  FSocketTalk.WaitServer;

  FSessionConnected := FSocketTalk.ServerResult;
  Result := FSocketTalk.ServerResult;
end;

// POP3 Logon

function TPOP2000.Login: Boolean;
var
  MsgList: TStringList;
  Loop: Integer;
  cStat: String;

begin

  Result := False;

  if (not FSessionConnected) or (not FSocketTalk.ClientSocket.Active) then
  begin

    Exit;
  end;

  FSocketTalk.Talk('USER '+FUserName+#13#10, #13#10, stUser);
  FSocketTalk.WaitServer;

  if FSocketTalk.ServerResult then
  begin

    FSocketTalk.Talk('PASS '+FPassword+#13#10, #13#10, stPass);
    FSocketTalk.WaitServer;

    if FSocketTalk.ServerResult then
    begin

      FSessionLogged := True;

      FSocketTalk.Talk('LIST'#13#10, #13#10'.'#13#10, stList);
      FSocketTalk.WaitServer;

      if FSocketTalk.ServerResult then
      begin

        MsgList := TStringList.Create;
        MsgList.Text := FSocketTalk.LastResponse;

        if MsgList.Count > 2 then
        begin

          cStat := TrimSpace(MsgList[MsgList.Count-2]);

          FSessionMessageCount := StrToIntDef(Copy(cStat, 1, Pos(#32, cStat)-1), -1);

          if FSessionMessageCount > 0 then
          begin

            SetLength(FSessionMessageSize, FSessionMessageCount);

            for Loop := 1 to MsgList.Count-2 do
            begin

              cStat := TrimSpace(MsgList[Loop]);
              cStat := Copy(cStat, 1, Pos(#32, cStat)-1);

              if StrToIntDef(cStat, 0) > 0 then
                FSessionMessageSize[StrToInt(cStat)-1] := StrToIntDef(Copy(MsgList[Loop], Pos(#32, MsgList[Loop])+1, 99), 0);
            end;
          end;
        end
        else
        begin

          FSessionMessageCount := 0;
          SetLength(FSessionMessageSize, 0);
        end;

        MsgList.Free;
      end;
    end;
  end;

  Result := FSessionLogged;
end;

// POP3 Quit

function TPOP2000.Quit: Boolean;
begin

  Result := False;

  if (not FSessionConnected) or (not FSocketTalk.ClientSocket.Active) then
  begin

    Exit;
  end;

  FSocketTalk.Talk('QUIT'#13#10, #13#10, stQuit);
  FSocketTalk.WaitServer;

  if FSocketTalk.ServerResult then
  begin

    FSocketTalk.ClientSocket.Close;
    FSessionConnected := False;
    FSessionLogged := False;
    FSessionMessageCount := -1;
    Result := True;
  end;
end;

// Retrieve message#

function TPOP2000.RetrieveMessage(Number: Integer): Boolean;
var
  MailTxt: TStringList;

begin

  Result := False;
  FLastMessage := '';

  if not Assigned(FMailMessage) then
  begin

    Exception.Create('MailMessage unassigned');
    Exit;
  end;

  if (not FSessionConnected) or (not FSessionLogged) or (not FSocketTalk.ClientSocket.Active) then
  begin

    Exit;
  end;

  FSocketTalk.DataSize := FSessionMessageSize[Number-1];
  FSocketTalk.Talk('RETR '+IntToStr(Number)+#13#10, #13#10'.'#13#10, stRetr);
  FSocketTalk.WaitServer;

  if FSocketTalk.ServerResult then
  begin

    MailTxt := TStringList.Create;
    MailTxt.Text := FSocketTalk.LastResponse;
    MailTxt.Delete(MailTxt.Count-1);
    MailTxt.Delete(0);
    FLastMessage := MailTxt.Text;
    FMailMessage.Reset;
    FMailMessage.Fill(PChar(FLastMessage), True);

    Result := True;
  end;
end;

// Delete message#

function TPOP2000.DeleteMessage(Number: Integer): Boolean;
begin

  Result := False;

  if (not FSessionConnected) or (not FSessionLogged) or (not FSocketTalk.ClientSocket.Active) then
  begin

    Exit;
  end;

  FSocketTalk.Talk('DELE '+IntToStr(Number)+#13#10, #13#10, stDele);
  FSocketTalk.WaitServer;

  if FSocketTalk.ServerResult then
  begin

    Result := True;
  end;
end;

{ TSMTP2000 ====================================================================== }

// Initialize TSMTP2000

constructor TSMTP2000.Create;
begin

  FSocketTalk := TSocketTalk.Create(Self);
  FSocketTalk.OnEndOfData := EndOfData;
  FSocketTalk.OnSocketTalkError := SocketTalkError;
  FSocketTalk.OnReceiveData := ReceiveData;
  FSocketTalk.OnDisconnect := SocketDisconnect;

  FHost := '';
  FPort := 25;
  FSessionConnected := False;
  FProxyPort := 23;
  FProxyHost := '';
  FProxyUsage := False;
  FProxyString := '%h% %p%';
  FPacketSize := 1024;

  inherited Create(AOwner);
end;

// Finalize TSMTP2000

destructor TSMTP2000.Destroy;
begin

  FSocketTalk.Free;

  inherited Destroy;
end;

// Set timeout

procedure TSMTP2000.SetTimeOut(Value: Integer);
begin

  FSocketTalk.TimeOut := Value;
end;

// Get timeout

function TSMTP2000.GetTimeOut: Integer;
begin

  Result := FSocketTalk.TimeOut;
end;

// Set OnProgress event

procedure TSMTP2000.SetProgress(Value: TProgressEvent);
begin

  FSocketTalk.OnProgress := Value;
end;

// Get OnProgress event

function TSMTP2000.GetProgress: TProgressEvent;
begin

  Result := FSocketTalk.OnProgress;
end;

// Get LastResponse

function TSMTP2000.GetLastResponse: String;
begin

  Result := FSocketTalk.LastResponse;
end;

// When data from server ends

procedure TSMTP2000.EndOfData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
begin

  case SessionState of

    stProxy: ServerResult := True;

    stConnect:
    if Copy(Data, 1, 3) = '220' then
      ServerResult := True;

    stHelo, stMail, stRcpt, stSendData:
    if Copy(Data, 1, 3) = '250' then
      ServerResult := True;

    stData:
    if Copy(Data, 1, 3) = '354' then
      ServerResult := True;

    stQuit:
    if Copy(Data, 1, 3) = '221' then
      ServerResult := True;
  end;
end;

// On socket error

procedure TSMTP2000.SocketTalkError(Sender: TObject; SessionState: TSessionState; TalkError: TTalkError);
begin

  FSocketTalk.Cancel;
end;

// On data received

procedure TSMTP2000.ReceiveData(Sender: TObject; SessionState: TSessionState; Data: String; var ServerResult: Boolean);
begin

  if (StrToIntDef(Copy(Data, 1, 3), 0) >= 500) and (Copy(Data, Length(Data)-1, 2) = #13#10) then
  begin

    ServerResult := False;
    FSocketTalk.Cancel;
  end;
end;

// On socket disconnected

procedure TSMTP2000.SocketDisconnect(Sender: TObject);
begin

  FSessionConnected := False;
end;

// Connect socket

function TSMTP2000.Connect: Boolean;
var
  Connect: String;
begin

  Result := False;

  if FSessionConnected or FSocketTalk.ClientSocket.Active then
  begin

    Exit;
  end;

  if Length(FHost) = 0 then
  begin

    Exit;
  end;

  if not FProxyUsage then
  begin

    if not IsIPAddress(FHost) then
    begin

      FSocketTalk.ClientSocket.Host := FHost;
      FSocketTalk.ClientSocket.Address := '';
    end
    else
    begin

      FSocketTalk.ClientSocket.Host := '';
      FSocketTalk.ClientSocket.Address := FHost;
    end;

    FSocketTalk.ClientSocket.Port := FPort;
    FSocketTalk.ForceState(stConnect);
    FSocketTalk.ClientSocket.Open;
  end
  else
  begin

    Connect := FindReplace(FProxyString, '%h%', FHost);
    Connect := FindReplace(Connect, '%p%', IntToStr(FPort));

    if not IsIPAddress(FProxyHost) then
    begin

      FSocketTalk.ClientSocket.Host := FProxyHost;
      FSocketTalk.ClientSocket.Address := '';
    end
    else
    begin

      FSocketTalk.ClientSocket.Host := '';
      FSocketTalk.ClientSocket.Address := FProxyHost;
    end;

    FSocketTalk.ClientSocket.Port := FProxyPort;
    FSocketTalk.ForceState(stProxy);
    FSocketTalk.ClientSocket.Open;
    FSocketTalk.WaitServer;

    if FSocketTalk.ServerResult then
      FSocketTalk.Talk(Connect+#13#10, #13#10, stConnect);
  end;

  FSocketTalk.WaitServer;

  if FSocketTalk.ServerResult then
  begin

    FSocketTalk.Talk('HELO '+FSocketTalk.FClientSocket.Socket.LocalHost+#13#10, #13#10, stHelo);
    FSocketTalk.WaitServer;

  end;
  
  FSessionConnected := FSocketTalk.ServerResult;
  Result := FSocketTalk.ServerResult;
end;

// SMTP Quit

function TSMTP2000.Quit: Boolean;
begin

  Result := False;

  if (not FSessionConnected) or (not FSocketTalk.ClientSocket.Active) then
  begin

    Exit;
  end;

  FSocketTalk.Talk('QUIT'#13#10, #13#10, stQuit);
  FSocketTalk.WaitServer;

  if FSocketTalk.ServerResult then
  begin

    FSocketTalk.ClientSocket.Close;
    FSessionConnected := False;
    Result := True;
  end;
end;

// Send message

function TSMTP2000.SendMessage: Boolean;
var
  Dests: TStringList;
  Loop: Integer;
  AllOk: Boolean;
  sHeader: String;
  sText: String;
  sBCC: String;

begin

  Result := False;

  if not Assigned(FMailMessage) then
  begin

    Exception.Create('MailMessage unassigned');
    Exit;
  end;

  if (not FSessionConnected) or (not FSocketTalk.ClientSocket.Active) then
  begin

    Exit;
  end;

  if FMailMessage.FNeedRebuild then
  begin

    Exception.Create('MailMessage need rebuild');
    Exit;
  end;

  Dests := TStringList.Create;
  Dests.Sorted := True;
  Dests.Duplicates := dupIgnore;

  for Loop := 0 to FMailMessage.ToCount-1 do
    Dests.Add(FMailMessage.ToAddress[Loop]);

  for Loop := 0 to FMailMessage.CcCount-1 do
    Dests.Add(FMailMessage.CcAddress[Loop]);

  for Loop := 0 to FMailMessage.BccCount-1 do
    Dests.Add(FMailMessage.BccAddress[Loop]);

  sBCC := FMailMessage.GetLabelValue('Bcc:');

  FMailMessage.SetMessageId(FSocketTalk.ClientSocket.Socket.LocalAddress);
  FMailMessage.ClearBcc;

  FSocketTalk.OnProcess := FOnProcess;
  
  FSocketTalk.Talk('MAIL FROM: <'+FMailMessage.GetFromAddress+'>'#13#10, #13#10, stMail);
  FSocketTalk.WaitServer;

  if FSocketTalk.ServerResult then
  begin

    AllOk := True;

    for Loop := 0 to Dests.Count-1 do
    begin

      FSocketTalk.Talk('RCPT TO: <'+Dests[Loop]+'>'#13#10, #13#10, stRcpt);
      FSocketTalk.WaitServer;

      if not FSocketTalk.ServerResult then
        AllOk := False;
    end;

    if AllOk then
    begin

      FSocketTalk.Talk('DATA'#13#10, #13#10, stData);
      FSocketTalk.WaitServer;

      if FSocketTalk.ServerResult then
      begin

        SetLength(sText, FMailMessage.FBody.Size);
        FMailMessage.FBody.Position := 0;
        FMailMessage.FBody.ReadBuffer(sText[1], FMailMessage.FBody.Size);

        WrapSL(FMailMessage.FHeader, sHeader, 70);

        FSocketTalk.PacketSize := FPacketSize;
        FSocketTalk.Talk(sHeader+#13#10+sText+#13#10'.'#13#10, #13#10, stSendData);
        FSocketTalk.WaitServer;

        if FSocketTalk.ServerResult then
        begin

          Result := True;
        end;
      end;
    end;
  end;

  FMailMessage.SetLabelValue('Bcc:', sBCC);
  Dests.Free;
end;

// =============================================================================

begin

  Randomize;
end.
