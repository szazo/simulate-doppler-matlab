distance_from_road_m = 20; % observer's distance from the road
car_speed_kmh = 100; % car's speed in km/h
temperature_c = 20; % outside temperature in celsius

test_sound('siren1_loop_ready.wav', 'siren1_output.wav', distance_from_road_m, car_speed_kmh, temperature_c);
test_sound('siren2_loop_ready.wav', 'siren2_output.wav', distance_from_road_m, car_speed_kmh, temperature_c);

function test_sound(sound_filename, output_filename, ...
    distance_from_road_m, car_speed_kmh, temperature_c) 

    [y, fs] = audioread(sound_filename); % load
    y = mean(y, 2); % stereo -> mono

    output = doppler(car_speed_kmh, y, fs, distance_from_road_m, temperature_c); % calculate

    audiowrite(output_filename, output, fs);
    sound(output, fs);
     figure, plot(output)
     xlabel('Time (s)')
     ylabel('Amplitude')
     [f, ft, tt] = spectrogram(output, 800, [], [], fs);
     figure, imagesc(tt, ft, abs(f))
     xlabel('Time (s)'), ylabel('Frequency (Hz)')

    pause(length(output) / fs);
end
