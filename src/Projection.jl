using FileIO, Images

function unproject(image_path)
    image = load(image_path)
    num_rows, num_cols = size(image)
    image_x = [2921, 1133, 835, 3398]
    image_y = [2796, 2780, 245, 294]
    world_x = [1, 0, 0, 1]
    world_y = [1, 1, 0, 0]
    A = zeros(Float64, (8,8))
    b = zeros(8)
    for i in 1:4
        A[2*i-1,:] = [world_x[i], world_y[i], 1, 0, 0, 0, -world_x[i]*image_x[i], -world_y[i]*image_x[i]]
        A[2*i,:] = [0, 0, 0, world_x[i], world_y[i], 1, -world_x[i]*image_y[i], -world_y[i]*image_y[i]]
        b[2*i-1] = image_x[i]
        b[2*i] = image_y[i]
    end
    h = A \ b
    H = [
        h[1] h[2] h[3]
        h[4] h[5] h[6]
        h[7] h[8] 1
    ]

    world_coords = zeros(Float64, (num_rows, num_cols, 2))
    for row in 1:num_rows
        for col in 1:num_cols
            world_coord = H \ [row, col, 1]
            world_coord = world_coord ./ world_coord[3]
            world_coords[row,col,:] = world_coord[1:2]
        end
    end

    min_world_row = min(world_coords[:,:,1]...)
    max_world_row = max(world_coords[:,:,1]...)
    min_world_col = min(world_coords[:,:,2]...)
    max_world_col = max(world_coords[:,:,2]...)
    m_row = (num_rows-1)/(max_world_row-min_world_row)
    m_col = (num_cols-1)/(max_world_col-min_world_col)

    final_image = zeros(RGB, (num_rows, num_cols))

    for row in 1:num_rows
        for col in 1:num_cols
            world_coord = world_coords[row,col,:]
            final_coord = round.(Int, [m_row*(world_coord[1]-min_world_row)+1, m_col*(world_coord[2]-min_world_col)+1])
            final_image[final_coord[1], final_coord[2]] = image[row,col]
        end
    end

    final_image
end

final_image = unproject("images/world.jpg")

save("images/world_unprojected.jpg", final_image)