program DebugPrj;

uses
  Forms,
  dbg in 'dbg.pas' {panel};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(Tpanel, panel);
  Application.Run;
end.
