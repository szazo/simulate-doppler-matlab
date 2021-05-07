function output = doppler(car_speed_kmh,  s, fs, ...
    distance_from_road_m, temperature_c)
    % Transforms the input sound using doppler and inverse square law
    % effect to simulate passing ambulance car's sound distortion.
    % car_speed_kmh: The car's speed in km/h.
    % s: The input loop ready sound.
    % fs: The input sound's sampling frequency
    % distance_from_road_m: The observer's distance from the road in m
    % temperature_c: The temperature in celsius

    sound_speed_ms = 20.05 * sqrt(temperature_c + 273.15); % sound speed based on temperature
    car_speed_ms = car_speed_kmh / 3.6; % car speed in m/s

    distance_m = inverse_intensity_distance(0.01); % start from distance where intensity is 1%
    car_start_distance_m = distance_m; % starting distance from the observer
    car_end_distance_m = distance_m; % ending distance from the observer

        % Calculates the current distance of the car on the road for
        % the given time.
        function distance_road_m = current_distance_on_road_m(t_seconds)
            distance_road_m = car_start_distance_m - car_speed_ms * t_seconds;
        end

        % Calculates the observer's current distance from the car.
        function distance_m = current_distance_m(distance_on_road_m)
            distance_m = sqrt(distance_from_road_m ^ 2 + distance_on_road_m ^ 2);
        end

        % Calculates cosine of the angle between the observer and the sound
        % source.
        function cos_theta = current_cos_theta(distance_on_road_m)
            theta = atan2(distance_from_road_m, distance_on_road_m);
            cos_theta = cos(theta);
        end

        % Calculates doppler frequency ratio based on the current distance
        % and speed.
        function [ frequency_ratio, cos_theta ] = calculate_doppler(d_on_road_m)
            cos_theta = current_cos_theta(d_on_road_m); % cos theta angle of the car
            frequency_ratio = sound_speed_ms / (sound_speed_ms - car_speed_ms * cos_theta); % current doppler frequency ratio
        end

        % Calculates intensity ratio based on the observer's distance from
        % the sound source (using inverse square law).
        function intensity_ratio = calculate_intensity_ratio(d_m)
            distance_ratio = d_m / distance_from_road_m;            
            intensity_ratio = (1 / distance_ratio) ^ 2;
        end

        % Calculates distance for the specified intensity (using inverse of
        % the inverse square law)
        function d_m = inverse_intensity_distance(intensity)
            d_m = distance_from_road_m / sqrt(intensity);
        end

        % Resamples the specified wsource window's frequency domain based
        % on the specified frequency ratio.
        function reconstructed = resample_window(freq_ratio, wsource)
            
            [ p, q ] = rat(freq_ratio); % rational approximation of the frequency
            if (p * q >= 2^31)
                % fix for too big ratios, which cannot be used by resample
                p = round(p / 2);
                q = round(q / 2);
            end

            f = fft(wsource); % frequency domain
            f_lower = f(1:end / 2); % lower part of the domain
            f_resampled = resample(f_lower, p, q); % resample
            if (length(f_resampled) > length(f_lower))
                f_resampled_with_zeros = f_resampled(1:length(f_lower)); % fix window size
            else
                f_resampled_with_zeros = [f_resampled; zeros(length(f_lower) - length(f_resampled), 1)]; % zero padding
            end
            f_extended = [f_resampled_with_zeros; 0; conj(f_resampled_with_zeros(end:-1:2))]; % symmetry for the inverse fourier transform
            reconstructed = real(ifft(f_extended)); % inverse fourier transform            
        end

    whole_distance_m = car_start_distance_m + car_end_distance_m;
    t_end = whole_distance_m / car_speed_ms; % the ending time of the simulation

    sample_end = t_end * fs; % the end of the  calculate

    w = 800; % half of the window size
    hann_window = hann(2 * w); % used for half overlapping windowing
    N = ceil(sample_end / w); % number of windows

    slice_func = loopable_sound_slice(s); % function for slicing loopable sound

    output = zeros(w * N, 1);
    for i = 1:N-1
        w_start = (i-1) * w + 1; % start sample point of the window
        w_end = (i + 1) * w; % end sample point of the window

        wt_start = w_start / fs; % start time of the window

        t = wt_start; % we use the start of the window for amplitude and frequency calculation

        d_on_road_m = current_distance_on_road_m(t); % car distance on the road
        d_m = current_distance_m(d_on_road_m); % real distance from the car

        intensity_ratio = calculate_intensity_ratio(d_m);
        [ frequency_ratio, cos_theta ] = calculate_doppler(d_on_road_m);

        wsource = slice_func(w_start, w_end); % get the slice for the current window from the loopable sound
        wsource_with_hann = hann_window .* wsource; % half overlapping hann window

        reconstructed = intensity_ratio .* resample_window(frequency_ratio, wsource_with_hann); % frequency and amplitude change

        output(w_start:w_end) = output(w_start:w_end) + reconstructed;

        fprintf('%.2fs (%d,%d): distance on road: %.3fm; distance: %.3fm; intensity: %.6f; cos_theta: %.6f; freq_ratio: %.6f\r\n', ...
            t, w_start, w_end, d_on_road_m, d_m, intensity_ratio, cos_theta, frequency_ratio);

    end
    
    % filter using normalized gauss filter
    N = 5; % filter kernel size
    filter_win = gausswin(N);
    filter_win = filter_win / sum(filter_win);
    
    output = filter(filter_win, 1, output);

end