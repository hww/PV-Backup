program pc2n64prj;

uses
  Forms,
  pc2n64 in 'pc2n64.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'PC to n64 upload and monitor';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
