+ split mkdir -p and cd commands in chdir
+ port shell/buffer and session tests
+ specify what happens when an invalid language is given

- make sure that config values don't come in as bogus arrays (such as :rvm => ['1.9.2'])
- make sure that all the asserted shell commands actually return 0 on success and 1 on failure
- make sure the config passed to Shell::Session contains timeouts and the buffer interval
- port recent commits where necessary
