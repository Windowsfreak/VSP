-module(server).
-compile([export_all]).

{ok, ServerCfg} = file:consult("server.cfg"),
{ok, MaxLength} = get_config_value(maxLength, ServerCfg),

loop() ->
	true. % TODO