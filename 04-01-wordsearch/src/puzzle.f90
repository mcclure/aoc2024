program puzzle
    use, intrinsic :: iso_fortran_env, only : error_unit

    character(len=4) :: goal
    integer,allocatable :: board(:)

    character(len=:), allocatable :: path

    goal = "XMAS"

    if (1 /= command_argument_count()) then
        write(error_unit,*) "Expected 1 argument (filename)" ! write to stderr
        error stop
    end if

    call get_command_argument(1, path)

    write(error_unit,*) path ! write to stderr

    open(10,file=path)
end program puzzle


