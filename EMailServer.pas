unit EMailServer;

interface

uses
  EMailData, Person,
  {OleServer, Outlook8, Mail2000, }IdBaseComponent, IdComponent, 
  IdEMailAddress, IdTCPConnection, IdTCPClient, IdMessageClient, IdSMTP, IdMessage,
  IdPOP3;
  
  
  procedure EMail(ASubject,AMessage : String; ATo : TPersons); overload;
  procedure EMail(ASubject,AMessage : String; ATo : TPerson); overload;
  
implementation

procedure EMail(ASubject,AMessage : String; ATo : TPersons);
var
  C : Integer;
  Frm : TFrmEMail;
  Per : TPerson;
  Count : Integer;
  Rcp : TIdEMailAddressItem;
begin
////  Frm := TFrmEMail.Create(Nil);
////
////  if Frm.SMTP.Password<>'' then begin
////    {Get the results then e-mail them to the people who have requested the info}
////    Count := 0;
////    Frm.SMTPMsg.Clear;
////    for C := 0 to ATo.Count-1 do { Iterate } begin
////      Per := ATo[C];
////      if Per.EMail<>'' then begin
////        Frm.SMTPMsg.From.Name := 'beasty';
////        Frm.SMTPMsg.From.Address := 'beasty@moatingodseye.co.uk';
////        Rcp := Frm.SMTPMsg.Recipients.Add;
////        Rcp.Name := Per.UserName;
////        Rcp.Address := Per.EMail;
////        Inc(Count);
////      end;
////    end;
////    if Count>0 then begin
////      Frm.SMTPMsg.Subject := ASubject;
////      Frm.SMTPMsg.Body.Add(AMessage);
////  //    TIdAttachment.Create(Frm.SMTPMsg.MessageParts, '\\jrbxp\data\overall'+Format('%8.0f',[Date])+'.HTML');
////      Frm.SMTP.Connect;
////      Frm.SMTP.Send(Frm.SMTPMsg);
////      Frm.SMTP.Disconnect;
////    end;
////  end;
////  Frm.Free;
end;

procedure EMail(ASubject,AMessage : String; ATo : TPerson); 
var
  lPersons : TPersons;
begin
  lPersons := TPersons.Create(False);
  lPersons.Add(ATo);
  EMail(ASubject,AMessage,lPersons);
  lPersons.Free;
end;

end.
