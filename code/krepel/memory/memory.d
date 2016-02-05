module krepel.memory.memory;

alias B   = a => cast(size_t)a;

alias KiB = a => a * 1024.B;
alias MiB = a => a * 1024.KiB;
alias GiB = a => a * 1024.MiB;
alias TiB = a => a * 1024.GiB;
alias PiB = a => a * 1024.TiB;

alias KB = a => a * 1000.B;
alias MB = a => a * 1000.KiB;
alias GB = a => a * 1000.MiB;
alias TB = a => a * 1000.GiB;
alias PB = a => a * 1000.TiB;
