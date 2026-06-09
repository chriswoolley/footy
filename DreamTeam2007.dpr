program DreamTeam2007;

uses
  Forms,
  Database in 'Database.pas' {dmData: TDataModule},
  DreamTeamMain in 'DreamTeamMain.pas' {FrmDreamTeamScore},
  Player in 'Player.pas',
  Excel in 'Excel.pas',
  Excel_TLB in 'Excel_TLB.pas',
  Office_TLB in 'Office_TLB.pas',
  VBIDE_TLB in 'VBIDE_TLB.pas',
  Utilities in 'Utilities.pas',
  Login in 'Login.pas' {FrmLogin},
  Person in 'Person.pas',
  DreamTeam in 'DreamTeam.pas' {FrmDreamTeam},
  Players in 'Players.pas' {FrmPlayers},
  Team in 'Team.pas',
  Squad in 'Squad.pas',
  Point in 'Point.pas',
  Previous in 'Previous.pas',
  Constants in 'Constants.pas',
  Audit in 'Audit.pas',
  EMailServer in 'EMailServer.pas',
  EMailData in 'EMailData.pas' {FrmEMail},
  PaperTalks in 'PaperTalks.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.ShowMainForm := False;
  Application.CreateForm(TFrmDreamTeamScore, FrmDreamTeamScore);
  Application.Run;
end.
