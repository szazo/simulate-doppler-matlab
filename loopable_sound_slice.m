function slice_func = loopable_sound_slice(sound)

    sound = sound(:); % convert to column vector
    l = length(sound);
    
    function sound_slice = slice(s_start, s_end)        
        
        if ((s_end - s_start + 1) > l)
            error('Window that larger than the sound is not allowed');
        end
        
        m_start = s_start;
        if (m_start > l) 
            m_start = mod(s_start, l); 
        end
        m_end = s_end;
        if (m_end > l) 
            m_end = mod(s_end, l); 
        end
                
        if (m_start <= m_end)
            sound_slice = sound(m_start:m_end);
        else
            sound_slice = [sound(m_start:l); sound(1:m_end)];
        end
    end
    
    slice_func = @slice;
end