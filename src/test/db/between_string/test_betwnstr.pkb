create or replace package body test_betwnstr as

  procedure normal_case is
  begin
    ut.expect( betwnstr( '1234567', 2, 5 ) ).to_equal('2345');
  end;

  procedure zero_start_position is
  begin
    ut.expect( betwnstr( '1234567', 0, 5 ) ).to_( equal('12345') );
  end;

  procedure big_end_position is
  begin
    ut.expect( betwnstr( '1234567', 0, 500 ) ).to_( equal('1234567') );
  end;

  procedure null_string is
  begin
    ut.expect( betwnstr( null, 2, 5 ) ).to_( be_null() );
  end;

  procedure bad_params is
  begin
    ut.expect( betwnstr( '1234567', 'a', 'b' ) ).to_( be_null() );
  end;

  procedure bad_test
  is
  begin
    ut.expect( betwnstr( '1234567', 0, 500 ) ).to_( equal('1') );
  end;

  procedure disabled_test is
  begin
    ut.expect( betwnstr( null, null, null) ).not_to( be_null );
  end;

end;
/
