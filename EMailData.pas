unit EMailData;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IdPOP3, IdMessage, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdMessageClient, IdSMTP;

type
  TFrmEMail = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmEMail: TFrmEMail;

implementation

{$R *.DFM}

end.
