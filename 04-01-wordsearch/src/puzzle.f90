! Assumes FORTRAN 2023 standard
program puzzle
    use, intrinsic :: iso_fortran_env, only : error_unit

    character(len=4) :: goal
    integer,allocatable :: board(:)
    logical :: file_done, line_done

    character(len=:), allocatable :: path
    character :: char_in
    integer :: path_length, line_length, file_error

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
    allocate(Character (path_length) :: path)
    call get_command_argument(1, path)

    ! Because automatic deferred length initialization is not working as expected,
    ! Don't try to read in the lines entire and instead read in character by character.
    open(10,file=path,access='stream',form='unformatted',action="read",iostat=file_error)
    if (0 /= file_error) then
        write(error_unit,*) "File error", file_error ! write to stderr
        if (file_error == 2) write(error_unit,*) "(No such file)"
        error stop
    end if
    do
        read(10, iostat=file_error) char_in
        if (file_error > 0) then
            write(error_unit,*) "File read error", file_error ! write to stderr
            error stop
        end if
        file_done = file_error == -1
        line_done = file_done .or. char_in == '\r' .or. char_in == '\n'
        ! DO LOGIC HERE
        if (file_done) exit
        ! DO LOGIC HERE
        print *, char_in ! DELETE ME
    end do
    print *,line_length,line_in
end program puzzle
