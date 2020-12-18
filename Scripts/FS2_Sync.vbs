option explicit

sub main
    dim wise_tele : set wise_tele = createobject("Wise.Tele")

    wise_tele.c28_sync_to_absolute_encoders
end sub
