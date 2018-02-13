function [ maze_image, seed ] = generate_prim_maze( ...
    maze_size, ...
    scale, ...
    wall_thickness, ...
    initial_element, ...
    seed ...
    )

assert( length( maze_size ) == 2 );

if nargin < 5
    
    rng( 'shuffle' );
    rng_state = rng;
    seed = rng_state.Seed;
    
else
    
    rng( seed );
    
end

if nargin < 4
    
    initial_element = generate_initial_element( maze_size );
    
end

maze = zeros( maze_size );
frontier = containers.Map;
[ frontier, maze ] = push_frontier( frontier, maze, initial_element );

while ~isempty( frontier )
    
    element = pop_frontier( frontier );
    maze = set( maze, element, bitor( get( maze, element ), 32 ) );
    [ neighbors, directions ] = get_neighbors( element, maze_size );
    
    out_neighbors = select_out( neighbors, maze );
    [ frontier, maze ] = push_frontier( frontier, maze, out_neighbors );
    
    [ in_neighbor, in_direction ] = select_random_in_neighbor( ...
        neighbors, ...
        directions, ...
        maze ...
        );
    if isempty( in_neighbor )
        continue;
    end
    maze = create_passage( element, in_neighbor, in_direction, maze );
    
end

maze_image = draw( maze, scale, wall_thickness );

end


function initial_element = generate_initial_element( maze_size )

initial_element = [ randi( maze_size( 1 ) ) randi( maze_size( 2 ) ) ];

end


function [ frontier, maze ] = push_frontier( frontier, maze, elements )

symbols = 'a' : 'z';
for i = 1 : size( elements, 1 )
    
    element = elements( i, : );
    if get( maze, element ) > 0
        
        continue;
        
    else

        key = symbols( randi( numel( symbols ), [ 1 64 ] ) );
        while isKey( frontier, key )

            key = rand();

        end
        frontier( key ) = elements( i, : );
        maze = set( maze, element, 16 );
        
    end

end

end


function element = pop_frontier( frontier )

keyset = keys( frontier );
element = frontier( keyset{ 1 } );
remove( frontier, keyset{ 1 } );

end


function [ neighbors, directions ] = get_neighbors( ...
    element, ...
    maze_size ...
    )

cols = max( min( [ 1; -1; 0; 0 ] + element( 2 ), maze_size( 2 ) ), 1 );
rows = max( min( [ 0; 0; 1; -1 ] + element( 1 ), maze_size( 1 ) ), 1 );
neighbors = [ rows cols ];
directions = [ 1; 2; 4; 8 ];

self_rows = ismember( neighbors, element, 'rows' );
neighbors( self_rows, : ) = [];
directions( self_rows ) = [];

end


function neighbors = select_out( neighbors, maze )

out_rows = get_out_rows( neighbors, maze );
neighbors( ~out_rows, : ) = [];

end


function out_rows = get_out_rows( neighbors, maze )

out_rows = ~bitget( get( maze, neighbors ), 5 );

end


function [ neighbor, direction ] = select_random_in_neighbor( ...
    neighbors, ...
    directions, ...
    maze ...
    )

[ neighbors, directions ] = select_in( ...
    neighbors, ...
    directions, ...
    maze ...
    );
if ~isempty( neighbors )
    rand_row = randi( size( neighbors, 1 ) );
    neighbor = neighbors( rand_row, : );
    direction = directions( rand_row, : );
else
    neighbor = [];
    direction = [];
end

end


function [ neighbors, directions ] = select_in( ...
    neighbors, ...
    directions, ...
    maze ...
    )

in_rows = ~logical( bitget( get( maze, neighbors ), 6 ) );
neighbors( in_rows, : ) = [];
directions( in_rows ) = [];

end


function maze = create_passage( current, previous, direction, maze )

maze = set( ...
    maze, current, ...
    bitor( get( maze, current ), direction ) ...
    );
maze = set( ...
    maze, previous, ...
    bitor( get( maze, previous ), get_opposite( direction ) ) ...
    );

end


function opposite = get_opposite( direction )

switch direction
    case 1
        opposite = 2;
    case 2
        opposite = 1;
    case 4
        opposite = 8;
    case 8
        opposite = 4;
    otherwise
        error( 'direction must be one of  N=1, S=2, E=4, W=8' );
end

end


function maze_image = draw( maze, integer_scale, wall_thickness )

maze = maze.';
padded_scale = integer_scale + ( 2 * wall_thickness );
maze_size = size( maze );
maze_image = false( ...
    ( padded_scale - wall_thickness ) .* maze_size ...
    + wall_thickness ...
    );

for i = 1 : maze_size( 1 )
    
    for j = 1 : maze_size( 2 )
        
        tile = draw_tile( maze( i, j ), padded_scale, wall_thickness );
        [ rows, cols ] = get_image_rows_cols( ...
            i, j, ...
            padded_scale, ...
            wall_thickness ...
            );
        maze_image( rows, cols ) = or( maze_image( rows, cols ), tile );
        
    end
    
end

maze_image = ~maze_image;

end


function tile = draw_tile( value, padded_scale, wall_thickness )

wall = 1;
empty = 0;
tile = empty .* ones( padded_scale, padded_scale );
if ~bitget( value, 1 )
    tile( 1 : end, ( end - wall_thickness + 1 ) : end ) = wall;
end
if ~bitget( value, 2 )
    tile( 1 : end, 1 : wall_thickness ) = wall;
end
if ~bitget( value, 3 )
    tile( ( end - wall_thickness + 1 ) : end, 1 : end ) = wall;
end
if ~bitget( value, 4 )
    tile( 1 : wall_thickness, 1 : end ) = wall;
end
tile = tile.';

end


function [ rows, cols ] = get_image_rows_cols( ...
    i, j, ...
    padded_scale, ...
    wall_thickness ...
    )

ul_corner = get_ul_corner( i, j, padded_scale, wall_thickness );
rows = ul_corner( 1 ) : ul_corner( 1 ) + padded_scale - 1;
cols = ul_corner( 2 ) : ul_corner( 2 ) + padded_scale - 1;

end


function ul_corner = get_ul_corner( i, j, padded_scale, wall_thickness )

ul_corner = [ ...
    scale_up( i, padded_scale - wall_thickness ) ...
    scale_up( j, padded_scale - wall_thickness ) ...
    ];

end


function new = scale_up( old, scale )

new = ( ( old - 1 ) * scale ) + 1;

end


function maze = set( maze, element, value )

maze( element( 1 ), element( 2 ) ) = value;

end


function values = get( maze, elements )

indices = sub2ind( size( maze ), elements( :, 1 ), elements( :, 2 ) );
values = maze( indices );

end