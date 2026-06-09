program pGraph;

uses
  Forms,
  Graph in 'Graph.pas' {FrmGraph},
  Database in 'Database.pas' {dmData: TDataModule};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFrmGraph, FrmGraph);
  Application.Run;
end.
