unit EMailer;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, IdMessage, IdPOP3, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdMessageClient, IdSMTP;

type
  TForm1 = class(TForm)
    btnHeader: TButton;
    ListBox1: TListBox;
    SMTP: TIdSMTP;
    POP: TIdPOP3;
    POPMsg: TIdMessage;
    SMTPMsg: TIdMessage;
    btnConnect: TButton;
    btnDisconnect: TButton;
    btnDelete: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    procedure btnHeaderClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDeleteClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    lConnected : Boolean;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.btnHeaderClick(Sender: TObject);
var
  lCount : integer;
  C : Integer;
begin
  if lConnected then begin
    lCount := POP.CheckMessages;
    Label1.Caption := IntToStr(lCount)+' messages';
    C := 0;
    while C<StrToInt(Edit1.Text) do
    begin
      POP.RetrieveHeader(C,POPMsg);
      ListBox1.Items.Add(IntToStr(C)+' '+POPMsg.Headers.Text);
      Label1.Caption := IntToStr(C);
      Inc(C);      
    end;    { while }
  end;  
end;

procedure TForm1.btnConnectClick(Sender: TObject);
begin
  try
    POP.Connect;
    lConnected := True;
  except
    lConnected := False;
  end;
end;

procedure TForm1.btnDisconnectClick(Sender: TObject);
begin
  POP.Disconnect;
  lConnected := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  lConnected := False;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if lConnected then
    POP.Disconnect;
end;

procedure TForm1.btnDeleteClick(Sender: TObject);
var
  C : Integer;
begin
  for C := 0 to ListBox1.Items.Count-1 do begin
    if ListBox1.Selected[C] then begin
      POP.Delete(C);
    end;  
  end;
  ListBox1.Clear;
  POP.Disconnect;
  lConnected := False;
  POP.Connect;
  lConnected := True;
end;

end.
