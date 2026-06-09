unit Audit;

interface

uses
  Windows, Classes, SysUtils, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Database, Constants;

procedure DoAudit(AWho,AWhat : String);

implementation

procedure DoAudit(AWho,AWhat : String);
var
  lAuditsID : Integer;
  Qry : TOraQuery;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('SELECT NVL(MAX(AUDITSID)+1,1) AS ID FROM AUDITS');
      Open;
      lAuditsID := FieldByName('ID').AsInteger;
      Close;
      Clear;
      Add('INSERT INTO AUDITS (AUDITSID,AUDITWHO,AUDITWHEN,AUDITWHAT) ');
      Add('VALUES (:AUDITSID,:AUDITWHO,:AUDITWHEN,:AUDITWHAT)');
      ParamByName('AUDITSID').AsInteger := lAuditsID;
      ParamByName('AUDITWHO').AsString := AWho;
      ParamByName('AUDITWHEN').AsDateTime := Now;
      ParamByName('AUDITWHAT').AsString := AWhat;
      ExecSQL;
    end;    { with }
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;  
end;

end.
 