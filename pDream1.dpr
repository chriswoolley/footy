program pDream1;

uses
  Forms,
  Dream1 in 'Dream1.pas' {FrmDreamTeamScore},
  Player in 'Player.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFrmDreamTeamScore, FrmDreamTeamScore);
  Application.Run;
end.
