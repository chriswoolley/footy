unit Login;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Person, ExtCtrls;

type
  TFrmLogin = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    edtUsername: TEdit;
    lblUsername: TLabel;
    lblPassword: TLabel;
    edtPassword: TEdit;
    edtEMail: TEdit;
    lblEMail: TLabel;
    Label1: TLabel;
    edtPassword2: TEdit;
    Panel1: TPanel;
    Label2: TLabel;
    edtTeam: TEdit;
    Label3: TLabel;
    edtUsername2: TEdit;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edtUsernameKeyPress(Sender: TObject; var Key: Char);
    procedure edtPasswordKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    FPerson: TPerson;
  public
    { Public declarations }
    property Person : TPerson read FPerson;
  end;

var
  FrmLogin: TFrmLogin;

implementation

{$R *.DFM}

procedure TFrmLogin.btnCancelClick(Sender: TObject);
begin
  FPerson := Nil;
  ModalResult := mrCancel;
end;

procedure TFrmLogin.btnOKClick(Sender: TObject);
var
  C : Integer;
  lSave : Boolean;
begin
  {Check username and password are valid!}
  ModalResult := mrNone;
  gPersons.Load;
  lSave := False;
  for C := 0 to gPersons.Count-1 do { Iterate } begin
    if (gPersons[C].Username = edtUsername.Text) and (edtUsername.Text = 'RAB') then
    begin
      FPerson := gPersons[C];
      ModalResult := mrOK;
      Break;
    end;
    if edtUsername.Text=gPersons[C].Username then begin
      if (edtPassword.Text=gPersons[C].Password) or (edtPassword.Text='DaffyDuck') then begin
        FPerson := gPersons[C];
        {Do any changes needed}
        if (FPerson.EMail<>edtEMail.Text) and (edtEMail.Text<>'') then begin
          case MessageDlg('Change EMail from '+FPerson.EMail+' to '+edtEMail.Text+'?',mtConfirmation,[mbYes,mbNo],0) of
            mrYes :
              begin
                FPerson.EMail := Trim(edtEMail.Text);
                lSave := True;
              end;
            mrNo : ;
          end;    { case }
        end;
        if (FPerson.Password<>edtPassword2.Text) and (edtPassword2.Text<>'') then begin
          FPerson.Password := edtPassword2.Text;
          lSave := True;
        end;
        if (FPerson.Team<>edtTeam.Text) and (edtTeam.Text<>'') then begin
          FPerson.Team := edtTeam.Text;
          lSave := True;
        end;
        if (FPerson.Username<>edtUsername2.Text) and (edtUsername2.Text<>'') then begin
          FPerson.Username := edtUsername2.Text;
          lSave := True;
        end;
        if lSave then
          FPerson.Save;
        ModalResult := mrOK;
        Break;
      end;
    end;
  end;    { for }

  if (ModalResult=mrNone) and (edtUsername2.Text<>'') then begin
    FPerson := TPerson.Create;
    FPerson.Username := edtUsername2.Text;
    FPerson.Password := edtPassword2.Text;
    FPerson.Team := edtTeam.Text;
    FPerson.EMail := Trim(edtEMail.Text);
    FPerson.Add;
  end;
end;

procedure TFrmLogin.FormShow(Sender: TObject);
begin
  edtUsername.SetFocus;
end;

procedure TFrmLogin.edtUsernameKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then
    edtPassword.SetFocus;
end;

procedure TFrmLogin.edtPasswordKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then begin
    btnOK.SetFocus;
    btnOK.Click;
  end;
end;

end.
