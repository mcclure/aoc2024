! Assumes FORTRAN 2023 standard
program puzzle
    use, intrinsic :: iso_fortran_env, only : error_unit

    character(len=4) :: goal
    integer,allocatable :: board(:)

    character(len=:), allocatable :: path
    integer :: path_length

    goal = "XMAS"

    if (1 /= command_argument_count()) then
        write(error_unit,*) "Expected 1 argument (filename)" ! write to stderr
        error stop
    end if

    ! Although F2023 (see https://wg5-fortran.org/N2201-N2250/N2212.pdf section 2.2)
    ! supports a deferred-length string being length-initialized by get_command_argument,
    ! GNU FORTRAN as of 14.2.0 appears to not do this and the path out is an empty string.
    ! Therefore, call twice, once to get the path length, and then after allocating call again
    ! to get the path. If called with expected (conformant?) behavior this is harmless.
    call get_command_argument(1, path, path_length)
    print *, path_length, path
    allocate(Character (path_length) :: path)
    call get_command_argument(1, path)
    print *, path

    open(10,file=path)
end program puzzle


