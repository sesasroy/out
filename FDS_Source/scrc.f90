MODULE SCRC
            
USE PRECISION_PARAMETERS
USE GLOBAL_CONSTANTS
USE MESH_POINTERS
USE MEMORY_FUNCTIONS, ONLY: CHKMEMERR
USE COMP_FUNCTIONS, ONLY: SECOND, GET_FILE_NUMBER
USE MPI
 
IMPLICIT NONE

CHARACTER(255), PARAMETER :: scrchid='$Id$'
CHARACTER(255), PARAMETER :: scrcrev='$Revision$'
CHARACTER(255), PARAMETER :: scrcdate='$Date$'

PRIVATE

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Public structures (needed in main, read, divg, dump)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!----------------------------------------------------------------------------------------------------
!!! Public subroutines (initialization, solver, time measurement and revisioning)
!!!----------------------------------------------------------------------------------------------------
PUBLIC SCARC_SETUP                   
PUBLIC SCARC_SOLVER                 
PUBLIC SCARC_TIMINGS               
PUBLIC GET_REV_SCRC               

!!!----------------------------------------------------------------------------------------------------
!!! Public variables   (explanations in declaration part below)
!!! Note: For input parameters in character format corresponding INTEGER type-parameters will
!!! be introduced later to simplify inquiries
!!!----------------------------------------------------------------------------------------------------
PUBLIC SCARC_METHOD   
PUBLIC SCARC_SYSTEM  
PUBLIC SCARC_INITIAL  

PUBLIC SCARC_RESIDUAL  
PUBLIC SCARC_ITERATIONS       
PUBLIC SCARC_CAPPA     
PUBLIC SCARC_ACCURACY        
PUBLIC SCARC_ACCURACY_DIVERGENCE 
PUBLIC SCARC_ACCURACY_RELATIVE 

PUBLIC SCARC_MULTIGRID      
PUBLIC SCARC_MULTIGRID_LEVEL
PUBLIC SCARC_MULTIGRID_CYCLE
PUBLIC SCARC_MULTIGRID_COARSENING 
PUBLIC SCARC_MULTIGRID_INTERPOL 
PUBLIC SCARC_MULTIGRID_ITERATIONS       
PUBLIC SCARC_MULTIGRID_ACCURACY      

PUBLIC SCARC_KRYLOV      
PUBLIC SCARC_KRYLOV_ITERATIONS
PUBLIC SCARC_KRYLOV_ACCURACY

PUBLIC SCARC_SMOOTH     
PUBLIC SCARC_SMOOTH_ITERATIONS 
PUBLIC SCARC_SMOOTH_ACCURACY 
PUBLIC SCARC_SMOOTH_OMEGA 
PUBLIC SCARC_SMOOTH_NORM 

PUBLIC SCARC_PRECON      
PUBLIC SCARC_PRECON_ITERATIONS 
PUBLIC SCARC_PRECON_ACCURACY
PUBLIC SCARC_PRECON_OMEGA 

PUBLIC SCARC_COARSE      
PUBLIC SCARC_COARSE_ITERATIONS  
PUBLIC SCARC_COARSE_ACCURACY  
PUBLIC SCARC_COARSE_OMEGA
PUBLIC SCARC_COARSE_PRECON 
 
PUBLIC SCARC_DEBUG 
PUBLIC SCARC_LAYER 
!PUBLIC SCARC_MKL        !!! MKL code

!!!----------------------------------------------------------------------------------------------------
!!! corresponding declarations (with default settings)
!!!----------------------------------------------------------------------------------------------------

!!! General definitions
CHARACTER(20) :: SCARC_METHOD    = 'null'                     ! requested solver method (KRYLOV/MULTIGRID)
CHARACTER(20) :: SCARC_SYSTEM    = 'null'                     ! matrix storage technique (BANDED/COMPACT)
CHARACTER(20) :: SCARC_INITIAL   = 'null'                     ! initial solution (currently only default is used)

!!! General iteration parameters
REAL (EB)     :: SCARC_RESIDUAL             = -1.0_EB         ! residual of global selected solver
INTEGER       :: SCARC_ITERATIONS           =  0              ! number of iterations of selected ScaRC solver
REAL (EB)     :: SCARC_CAPPA                =  1.0_EB         ! convergence rate of selected ScarC solver
REAL (EB)     :: SCARC_ACCURACY_DIVERGENCE  = 1.E+6_EB        ! divergence epsilon for all solvers
REAL (EB)     :: SCARC_ACCURACY_RELATIVE    = 1.E-2_EB        ! minimum relative accuracy for all solvers
CHARACTER(20) :: SCARC_ACCURACY             = 'ABSOLUTE'      ! accuracy type (ABSOLUTE/RELATIVE)

!!! Parameters for multigrid-type methods
CHARACTER(20) :: SCARC_MULTIGRID               = 'GEOMETRIC'  ! type of MG-method (GEOMETRIC/ALGEBRAIC)
INTEGER       :: SCARC_MULTIGRID_LEVEL         = -1           ! User defined number of MG-levels (optionally)
CHARACTER(1)  :: SCARC_MULTIGRID_CYCLE         = 'V'          ! Cycling type  (F/V/W)
CHARACTER(20) :: SCARC_MULTIGRID_COARSENING    = 'RS3'        ! Coarsening strategy  (RS3/A1/A2/PMIS/FDS...)
CHARACTER(20) :: SCARC_MULTIGRID_INTERPOL      = 'DIRECT'     ! Interpolation strategy (DIRECT/RS/STANDARD)
INTEGER       :: SCARC_MULTIGRID_ITERATIONS    = 1000         ! max number of iterations
REAL (EB)     :: SCARC_MULTIGRID_ACCURACY      = 1.E-10_EB    ! requested accuracy for convergence

!!! Parameters for Krylov-type methods
CHARACTER(20) :: SCARC_KRYLOV            = 'CG'               ! type of Krylov-method (CG/BICG)
INTEGER       :: SCARC_KRYLOV_ITERATIONS = 1000               ! max number of iterations 
REAL (EB)     :: SCARC_KRYLOV_ACCURACY   = 1.E-12_EB          ! requested accuracy for convergence

!!! Parameters for smoothing method (used in multigrids-methods)
CHARACTER(20) :: SCARC_SMOOTH            = 'SSOR'             ! smoother for MG (JACOBI/SSOR/GSTRIX)
INTEGER       :: SCARC_SMOOTH_ITERATIONS = 10                 ! max number of iterations 
REAL (EB)     :: SCARC_SMOOTH_ACCURACY   = 1.E-12_EB          ! requested accuracy for convergence
REAL (EB)     :: SCARC_SMOOTH_OMEGA      = 0.90E+0_EB         ! relaxation parameter 
LOGICAL       :: SCARC_SMOOTH_NORM       = .FALSE.            ! compute L2-norm of defect during smoothing ?

!!! Parameters for preconditioning method (used in Krylov-methods)
CHARACTER(20) :: SCARC_PRECON            = 'SSOR'             ! preconditioner for CG/BICG (JACOBI/SSOR/GSTRIX/MG)
INTEGER       :: SCARC_PRECON_ITERATIONS = 1000               ! max number of iterations 
REAL (EB)     :: SCARC_PRECON_ACCURACY   = 1.E-12_EB          ! requested accuracy for convergence
REAL (EB)     :: SCARC_PRECON_OMEGA      = 0.9E+0_EB          ! relaxation parameter 

!!! Parameters for coarse grid method
CHARACTER(20) :: SCARC_COARSE            = 'ITERATIVE'        ! coarse grid solver (iterative/direct)
INTEGER       :: SCARC_COARSE_ITERATIONS = 100                ! max number of iterations for iterative variant
REAL (EB)     :: SCARC_COARSE_ACCURACY   = 1.E-12_EB          ! requested accuracy for convergencefor iterative variant
REAL (EB)     :: SCARC_COARSE_OMEGA      = 1.5E+0_EB          ! relaxation parameter for iterative variant
CHARACTER(20) :: SCARC_COARSE_PRECON     = 'SSOR'             ! preconditioner for iterative variant
 
!!! debugging parameters
CHARACTER(20) :: SCARC_DEBUG = 'NONE'                         ! debugging level (NONE/LESS/MEDIUM/MUCH)
CHARACTER(40) :: SCARC_FN                                     ! file name for ScaRC debug messages
INTEGER       :: SCARC_LU                                     ! unit number for ScaRC debug file
INTEGER       :: SCARC_LAYER = 1                              ! unit number for ScaRC debug file

!!! MKL library
!LOGICAL       :: SCARC_MKL = .FALSE.

INTEGER, PARAMETER :: IND_X = 1 , &
                      IND_Y = 2 , &
                      IND_Z = 3

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Private structures
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!----------------------------------------------------------------------------------------------------
!!! Global constants
!!!----------------------------------------------------------------------------------------------------
INTEGER, PARAMETER :: NSCARC_DIMENSION_NONE         = -1, &
                      NSCARC_DIMENSION_TWO          =  2, &      ! two-dimensional problem
                      NSCARC_DIMENSION_THREE        =  3         ! three-dimensional problem

INTEGER, PARAMETER :: NSCARC_SCOPE_NONE             = -1, &         
                      NSCARC_SCOPE_MAIN             =  1, &      ! method used as main solver
                      NSCARC_SCOPE_SMOOTH           =  2, &      ! method used as smoother
                      NSCARC_SCOPE_PRECON           =  3, &      ! method used as preconditiner
                      NSCARC_SCOPE_COARSE           =  4         ! method used as coarse grid solver

INTEGER, PARAMETER :: NSCARC_METHOD_NONE            = -1, &
                      NSCARC_METHOD_KRYLOV          =  1, &      ! Krylov   -method as global solver
                      NSCARC_METHOD_MULTIGRID       =  2         ! multigrid-method as global solver

INTEGER, PARAMETER :: NSCARC_KRYLOV_NONE            = -1, &
                      NSCARC_KRYLOV_CG              =  1, &      ! CG   as Krylov solver
                      NSCARC_KRYLOV_BICG            =  2         ! BICG as Krylov solver

INTEGER, PARAMETER :: NSCARC_MULTIGRID_NONE         = -1, &
                      NSCARC_MULTIGRID_GEOMETRIC    =  1, &      ! geometric multigrid
                      NSCARC_MULTIGRID_ALGEBRAIC    =  2         ! algebraic multigrid

INTEGER, PARAMETER :: NSCARC_SYSTEM_NONE            = -1, &
                      NSCARC_SYSTEM_BANDED          =  1, &      ! system in banded storage technique
                      NSCARC_SYSTEM_COMPACT         =  2         ! system in compact  storage technique

INTEGER, PARAMETER :: NSCARC_EXCHANGE_NONE          = -1, &
                      NSCARC_EXCHANGE_WALL          =  1, &      ! initialize wall information
                      NSCARC_EXCHANGE_VECTOR        =  2, &      ! matrix-vector communication 
                      NSCARC_EXCHANGE_BDRY          =  3, &      ! vector values along internal boundaries
                      NSCARC_EXCHANGE_MATRIX        =  4, &      ! internal subdiagonal matrix values 
                      NSCARC_EXCHANGE_MEASURE       =  5, &      ! measure values along internal boundaries
                      NSCARC_EXCHANGE_CELLTYPE      =  6, &      ! cell types along internal boundaries
                      NSCARC_EXCHANGE_CELLTYPE2     =  7, &      ! cell types II along internal boundaries
                      NSCARC_EXCHANGE_WEIGHTS       =  8, &      ! internal transfer weights
                      NSCARC_EXCHANGE_STENCIL       =  9, &      ! internal subdiagonal matrix values 
                      NSCARC_EXCHANGE_SIZE_MATRIXB  = 11, &      ! AMG-information on neighboring meshes
                      NSCARC_EXCHANGE_SIZE_MATRIXC  = 12, &      ! AMG-information on neighboring meshes
                      NSCARC_EXCHANGE_SIZE_TRANSFERC= 13, &      ! AMG-information on neighboring meshes
                      NSCARC_EXCHANGE_GRID          = 14, &      ! neighboring grid dimensions
                      NSCARC_EXCHANGE_ALLOC_REAL    = 15, &      ! allocate real exchange buffers
                      NSCARC_EXCHANGE_ALLOC_INT     = 16         ! allocate integer exchange buffers

INTEGER, PARAMETER :: NSCARC_SMOOTH_NONE            = -1, &
                      NSCARC_SMOOTH_JACOBI          =  1, &      ! smoothing by JACOBI-method
                      NSCARC_SMOOTH_SSOR            =  2, &      ! smoothing by SSOR-method
                      NSCARC_SMOOTH_GSTRIX          =  3, &      ! smoothing by GSTRIX-method
                      NSCARC_SMOOTH_FFT             =  4         ! smoothing by FFT-method

INTEGER, PARAMETER :: NSCARC_PRECON_NONE            = -1, &
                      NSCARC_PRECON_JACOBI          =  1, &      ! preconditioning by JACOBI-method
                      NSCARC_PRECON_SSOR            =  2, &      ! preconditioning by SSOR-method
                      NSCARC_PRECON_GSTRIX          =  3, &      ! preconditioning by GSTRIX-method
                      NSCARC_PRECON_FFT             =  4, &      ! preconditioning by FFT-method
                      NSCARC_PRECON_MULTIGRID       =  5         ! preconditioning by MG-method

INTEGER, PARAMETER :: NSCARC_CYCLE_NONE             = -1, &
                      NSCARC_CYCLE_F                =  0, &      ! F-cycle for mg-method
                      NSCARC_CYCLE_V                =  1, &      ! V-cycle for mg-method
                      NSCARC_CYCLE_W                =  2, &      ! W-cycle for mg-method
                      NSCARC_CYCLE_SETUP            =  3, &      ! initialize cycle counts
                      NSCARC_CYCLE_RESET            =  4, &      ! reset cycle counts
                      NSCARC_CYCLE_PROCEED          =  5, &      ! proceed cycle counts
                      NSCARC_CYCLE_PRESMOOTH        =  6, &      ! presmoothing cycle
                      NSCARC_CYCLE_POSTSMOOTH       =  7, &      ! postsmoothing cycle
                      NSCARC_CYCLE_NEXT             =  8, &      ! perform next cycling loop
                      NSCARC_CYCLE_EXIT             =  9         ! exit cycling loop

INTEGER, PARAMETER :: NSCARC_STATE_PROCEED           =  0, &      ! proceed loop
                      NSCARC_STATE_CONV              =  1, &      ! convergence
                      NSCARC_STATE_DIVG              =  2         ! divergence

INTEGER, PARAMETER :: NSCARC_DEBUG_NONE             = -1, &      ! no debugging requested
                      NSCARC_DEBUG_INFO0            =  0, &      ! info1  level of debugging requested
                      NSCARC_DEBUG_INFO1            =  1, &      ! info1  level of debugging requested
                      NSCARC_DEBUG_INFO2            =  2, &      ! info2  level of debugging requested
                      NSCARC_DEBUG_LESS             =  3, &      ! low    level of debugging requested
                      NSCARC_DEBUG_MEDIUM           =  4, &      ! medium level of debugging requested
                      NSCARC_DEBUG_MUCH             =  5, &      ! strong level of debugging requested
                      NSCARC_DEBUG_MATRIX           =  6, &      ! show matrix
                      NSCARC_DEBUG_MATRIXE          =  7, &      ! show matrix
                      NSCARC_DEBUG_IJKW             =  8, &      ! show IJKW
                      NSCARC_DEBUG_WALLINFO         =  9, &      ! show WALLINFO
                      NSCARC_DEBUG_BCINDEX          = 10, &      ! show PRESSURE_BC_INDEX
                      NSCARC_DEBUG_ACELL            = 11, &      ! show WALL_CELL
                      NSCARC_DEBUG_GCELL            = 12, &      ! show GHOST_CELL
                      NSCARC_DEBUG_NCELL            = 13, &      ! show NOM_CELL
                      NSCARC_DEBUG_SUBDIVISION      = 14, &      ! show SUBDIVISION
                      NSCARC_DEBUG_MEASURE          = 15, &      ! show MEASURE
                      NSCARC_DEBUG_CELLTYPE         = 16, &      ! show CELLTYPE
                      NSCARC_DEBUG_COARSE           = 17, &      ! show coarse grid
                      NSCARC_DEBUG_PROLONGATION     = 18, &      ! show prolongation matrix
                      NSCARC_DEBUG_RESTRICTION      = 19         ! show restriction matrix 

INTEGER, PARAMETER :: NSCARC_COARSENING_NONE        = -1, &
                      NSCARC_COARSENING_RS3         =  1, &      ! parallel Ruge-StÃ¼ben 
                      NSCARC_COARSENING_A1          =  2, &      ! aggressive 1 (path=1, length=2)
                      NSCARC_COARSENING_A2          =  3, &      ! aggressive 2 (path=2, length=2)
                      NSCARC_COARSENING_PMIS        =  5, &      ! PMIS 
                      NSCARC_COARSENING_PMISG       =  6, &      ! PMIS 
                      NSCARC_COARSENING_FDSRS3      =  7, &      ! FDSRS3 : FDS variant similar to RS3
                      NSCARC_COARSENING_FDSA1       =  8, &      ! FDSA1  : FDS variant similar to A1
                      NSCARC_COARSENING_FDSA2       =  9, &      ! FDSA2  : FDS variant similar to A2
                      NSCARC_COARSENING_BDRY        = 11         ! own boundary test

INTEGER, PARAMETER :: NSCARC_COARSE_NONE            = -1, &
                      NSCARC_COARSE_ITERATIVE       =  1, &      ! iterative solution of coarse grid problem
                      NSCARC_COARSE_DIRECT          =  2         ! direct solution of coarse grid problem

INTEGER, PARAMETER :: NSCARC_DIRECT_NONE            = -1, &
                      NSCARC_DIRECT_GE              =  1, &      ! direct solution by Gaussian elmination
                      NSCARC_DIRECT_LU              =  2         ! direct solution by LU-decomposition 

INTEGER, PARAMETER :: NSCARC_SIZE_NONE              = -1, &
                      NSCARC_SIZE_MATRIXB           =  1, &      ! size of system matrix for banded system
                      NSCARC_SIZE_MATRIXC           =  2, &      ! size of system matrix for compact system
                      NSCARC_SIZE_TRANSFERC         =  3         ! size of transfer matrices for compact system

INTEGER, PARAMETER :: NSCARC_VECTOR_NONE            = -1, &
                      NSCARC_VECTOR_X               =  1, &      ! selection parameter for vector X
                      NSCARC_VECTOR_F               =  2, &      ! selection parameter for vector F
                      NSCARC_VECTOR_Y               =  3, &      ! selection parameter for vector Y
                      NSCARC_VECTOR_G               =  4, &      ! selection parameter for vector G
                      NSCARC_VECTOR_W               =  5, &      ! selection parameter for vector R
                      NSCARC_VECTOR_D               =  6, &      ! selection parameter for vector D
                      NSCARC_VECTOR_Z               =  7, &      ! selection parameter for vector Z
                      NSCARC_VECTOR_X2              =  8, &      ! selection parameter for vector X2
                      NSCARC_VECTOR_G2              =  9, &      ! selection parameter for vector D2
                      NSCARC_VECTOR_D2              = 10, &      ! selection parameter for vector D2
                      NSCARC_VECTOR_W2              = 11, &      ! selection parameter for vector R2
                      NSCARC_VECTOR_Y2              = 12, &      ! selection parameter for vector Y2
                      NSCARC_VECTOR_Z2              = 13, &      ! selection parameter for vector Y2
                      NSCARC_VECTOR_H               = 14, &      ! selection parameter for vector Y2
                      NSCARC_VECTOR_HS              = 15, &      ! selection parameter for vector Y2
                      NSCARC_VECTOR_MEASURE         = 16, &      ! selection parameter for vector MEASURE
                      NSCARC_VECTOR_CELLTYPE        = 17, &      ! selection parameter for vector CELLTYPE
                      NSCARC_VECTOR_PTR             = 18         ! selection parameter for vector CELLTYPE

INTEGER, PARAMETER :: NSCARC_MATRIX_NONE            = -9999999, &
                      NSCARC_MATRIX_SUBDIAG         =  1, &      ! exchange subdiagonal matrix entries
                      NSCARC_MATRIX_SYSTEM          =  2, &      ! exchange system matrix entries 
                      NSCARC_MATRIX_TRANSFER        =  3, &      ! exchange prolongation matrix 
                      NSCARC_MATRIX_STENCIL         =  4, &      ! exchange prolongation matrix 
                      NSCARC_MATRIX_PROLONGATION    =  5, &      ! exchange prolongation matrix
                      NSCARC_MATRIX_RESTRICTION     =  6         ! exchange restriction matrix 

INTEGER, PARAMETER :: NSCARC_ACCURACY_NONE          = -1, &
                      NSCARC_ACCURACY_ABSOLUTE      =  1, &      ! absolute accuracy must be reached
                      NSCARC_ACCURACY_RELATIVE      =  2         ! relative accuracy must be reached

REAL(EB), PARAMETER:: NSCARC_MEASURE_NONE           =  0.0_EB, &
                      NSCARC_MEASURE_COARSE         =  6.0_EB, & ! coarse-grid cell
                      NSCARC_MEASURE_FINE           =  5.0_EB, & ! fine-grid cell
                      NSCARC_MEASURE_SFINE          =  5.0_EB, & ! strongly coupled fine-grid cell
                      NSCARC_MEASURE_WFINE          =  4.0_EB, & ! weakly   coupled fine-grid cell
                      NSCARC_MEASURE_BDRY           =  1.0_EB    ! boundry weight

INTEGER, PARAMETER :: NSCARC_CELLTYPE_NONE          =  0, &
                      NSCARC_CELLTYPE_COARSE        =  1, &      ! coarse-grid cell
                      NSCARC_CELLTYPE_FINE          = -2, &      ! fine-grid cell
                      NSCARC_CELLTYPE_SFINE         = -2, &      ! strongly coupled fine-grid cell
                      NSCARC_CELLTYPE_WFINE         = -3         ! weakly   coupled fine-grid cell

INTEGER, PARAMETER :: NSCARC_INTERPOL_NONE          =  0, &
                      NSCARC_INTERPOL_STANDARD      =  1, &      ! standard interpolation
                      NSCARC_INTERPOL_CLASSICAL     =  2, &      ! classical interpolation
                      NSCARC_INTERPOL_DIRECT        =  3, &      ! direct interpolation
                      NSCARC_INTERPOL_DIRECT_BDRY   =  4, &      ! direct interpolation with special boundary
                      NSCARC_INTERPOL_MULTIPASS     =  5         ! multipass interpolation

INTEGER, PARAMETER :: NSCARC_LATEX_NONE             = -1, &      ! no latex information requested
                      NSCARC_LATEX_STAGGERED        =  1, &      ! show staggered latex information
                      NSCARC_LATEX_EQUAL            =  2, &      ! show equal latex information
                      NSCARC_LATEX_NUMBER           =  3, &      ! show number latex information
                      NSCARC_LATEX_ALL              =  4, &      ! show all latex information
                      NSCARC_LATEX_TABLE            =  5         ! show latex table

INTEGER, PARAMETER :: NSCARC_TIME_NONE              = -1, &
                      NSCARC_TIME_TOTAL             =  1, &      ! time for complete ScaRC part of FDS
                      NSCARC_TIME_SETUP             =  2, &      ! time for setup phase
                      NSCARC_TIME_SOLVER            =  3, &      ! time for ScaRC solver 
                      NSCARC_TIME_KRYLOV            =  4, &      ! time for Krylov solver
                      NSCARC_TIME_MULTIGRID         =  5, &      ! time for multigrid solver
                      NSCARC_TIME_PRECON            =  6, &      ! time for preconditioner
                      NSCARC_TIME_SMOOTH            =  7, &      ! time for smoother
                      NSCARC_TIME_COARSE            =  8, &      ! time for coarse grid solver
                      NSCARC_TIME_MATVEC            =  9, &      ! time for matrix-vector product
                      NSCARC_TIME_SCALPROD          = 10, &      ! time for scalar product
                      NSCARC_TIME_L2NORM            = 11, &      ! time for l2norm
                      NSCARC_TIME_EXCH_INIT         = 12, &      ! time for exchange initialization
                      NSCARC_TIME_EXCH_VECTOR       = 13, &      ! time for exchange of internal boundary
                      NSCARC_TIME_EXCH_MATRIX       = 14, &      ! time for exchange of internal matrix
                      NSCARC_TIME_EXCH_MEASURE      = 15         ! time for exchange of internal measure

INTEGER, PARAMETER :: NSCARC_LEVEL_NONE             = -1, &      ! no predefined initial solution used
                      NSCARC_LEVEL_MIN              =  0, &      ! minimum multigrid level 
                      NSCARC_LEVEL_MAX              =  15        ! maximum multigrid level 

INTEGER, PARAMETER :: NSCARC_LAYER_NONE             = -1, &      ! no neighbor
                      NSCARC_LAYER_ONE              =  1, &      ! communication of one abutting layer
                      NSCARC_LAYER_TWO              =  2         ! communication of two abutting layers

INTEGER, PARAMETER :: NSCARC_STENCIL_NONE           = -1, &      ! no matrix stencil available
                      NSCARC_STENCIL_CENTRAL        =  1, &      ! standard 5- or 7-point stencil
                      NSCARC_STENCIL_AMG            =  2         ! arbitrary AMG-stencil

INTEGER, PARAMETER :: NSCARC_INITIAL_NONE           = -1         ! another initial function ?

INTEGER, PARAMETER :: NSCARC_COUPLING_MAX           = 10         ! maximum of possible couplings in stencil
 
INTEGER, PARAMETER :: NSCARC_DUMMY                  = -1         ! dummy variable (needed at several places)


!!!----------------------------------------------------------------------------------------------------
!!! Global variables 
!!!----------------------------------------------------------------------------------------------------
!!! use integer types for the user defined input data (based on SCARC_TYPE_... variables)
INTEGER :: TYPE_DIMENSION  = NSCARC_DIMENSION_NONE
INTEGER :: TYPE_SCOPE      = NSCARC_SCOPE_NONE
INTEGER :: TYPE_SCOPE0     = NSCARC_SCOPE_MAIN
INTEGER :: TYPE_METHOD     = NSCARC_METHOD_NONE
INTEGER :: TYPE_METHOD0    = NSCARC_METHOD_NONE
INTEGER :: TYPE_KRYLOV     = NSCARC_KRYLOV_NONE
INTEGER :: TYPE_MULTIGRID  = NSCARC_MULTIGRID_NONE
INTEGER :: TYPE_SYSTEM     = NSCARC_SYSTEM_NONE
INTEGER :: TYPE_MATRIX     = NSCARC_MATRIX_NONE
INTEGER :: TYPE_ACCURACY   = NSCARC_ACCURACY_NONE
INTEGER :: TYPE_SMOOTH     = NSCARC_SMOOTH_SSOR
INTEGER :: TYPE_PRECON     = NSCARC_PRECON_SSOR
INTEGER :: TYPE_PRECON0    = NSCARC_PRECON_SSOR
INTEGER :: TYPE_CYCLE      = NSCARC_CYCLE_V
INTEGER :: TYPE_COARSENING = NSCARC_COARSENING_NONE
INTEGER :: TYPE_INTERPOL   = NSCARC_INTERPOL_NONE
INTEGER :: TYPE_COARSE     = NSCARC_COARSE_NONE
INTEGER :: TYPE_DEBUG      = NSCARC_DEBUG_NONE   
INTEGER :: TYPE_INITIAL    = NSCARC_INITIAL_NONE
INTEGER :: TYPE_EXCHANGE   = NSCARC_EXCHANGE_NONE
INTEGER :: TYPE_VECTOR     = NSCARC_VECTOR_NONE
INTEGER :: TYPE_DIRECT     = NSCARC_DIRECT_NONE
INTEGER :: TYPE_LATEX      = NSCARC_LATEX_NONE
INTEGER :: TYPE_LAYER      = NSCARC_LAYER_ONE

!!! range of meshes which must be processed for MYID
INTEGER :: NMESHES_MIN, NMESHES_MAX                 
 
!!! total, minimum and maximum number of multigrid levels
INTEGER :: NLEVEL, NLEVEL_MAX, NLEVEL_MIN                              

INTEGER :: NMASTER, NC_COARSE0

!!! additional arrays for data exchange
INTEGER :: NREQ_SCARC, N_EXCHANGES, TAG_SCARC, SNODE, RNODE, STATUS2_SCARC(MPI_STATUS_SIZE)
INTEGER, ALLOCATABLE, DIMENSION (:)    :: REQ_SCARC

!!! time measurements with ScaRC
INTEGER, PARAMETER :: N_TIMERS_SCARC=18         
REAL(EB), ALLOCATABLE, DIMENSION(:,:) :: TUSED_SCARC

!!! auxiliary variables for global and local scalproducts, number of global cells and global dimensions
REAL(EB), ALLOCATABLE, DIMENSION (:) :: SP_LOCAL
INTEGER,  ALLOCATABLE, DIMENSION (:) :: NC_GLOBAL, NC_LOCAL
INTEGER,  ALLOCATABLE, DIMENSION (:) :: NA_COARSE, NC_COARSE, NX_COARSE, NY_COARSE, NZ_COARSE, NW_COARSE
REAL(EB), ALLOCATABLE, DIMENSION (:) :: DXI2_COARSE, DYI2_COARSE, DZI2_COARSE

!!! number of couplings in given matrix stencil and pointer to indices in matrix stencil on given level 
INTEGER :: ID, ILX, ILY, ILZ, IUX, IUY, IUZ

!!! counter and displacement arrays for global data exchanges
INTEGER, ALLOCATABLE, DIMENSION(:) :: COUNTS_SCARC, DISPLS_SCARC

 
!!! Private type declarations

!!!----------------------------------------------------------------------------------------------------
!!! Scope type for the declaration of the solver-dependent scopes
!!!----------------------------------------------------------------------------------------------------
TYPE SCARC_SCOPE_TYPE
INTEGER :: X, F, Y, G, W, D, Z                        ! logic number for dereferencing the solver vectors
INTEGER :: ITE, NIT
REAL(EB) :: EPS, RES, RESIN, OMEGA
CHARACTER(30) :: CROUTINE = 'null'
END TYPE SCARC_SCOPE_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! Scope type for the declaration of the solver-dependent scopes
!!!----------------------------------------------------------------------------------------------------
TYPE SCARC_PARENT_TYPE
INTEGER :: TYPE_METHOD, TYPE_SCOPE, TYPE_PRECON, TYPE_SMOOTH, TYPE_SYSTEM, TYPE_ACCURACY, TYPE_CYCLE
END TYPE SCARC_PARENT_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! OSCARC type for banded system information on other mesh
!!!----------------------------------------------------------------------------------------------------
TYPE OSCARC_BANDED_TYPE
INTEGER :: NX, NY, NZ, NC, NW, NA, NG, NP, NWS=0
INTEGER :: NGE, NGS, NPE, NPS, NA0
INTEGER :: NCC, NCCE, NCCS
INTEGER :: NCF, NCFE, NCFS
REAL(EB), POINTER, DIMENSION (:) :: A , X
TYPE (SCARC_WALL_TYPE), POINTER, DIMENSION(:) :: WALL
END TYPE OSCARC_BANDED_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! OSCARC type for mesh information on other mesh
!!! local numbers of cells (also per direction), wall cells, matrix entries
!!! neighborship structures 
!!!----------------------------------------------------------------------------------------------------
TYPE OSCARC_COMPACT_TYPE
INTEGER :: NX, NY, NZ, NC, NA, NW, NG, NP, NR, NWS=0
INTEGER :: NCC , NCF, NCE, NPE, NRE, NGE, NCCI
INTEGER :: NCC0, NCF0, NCE0, NP0, NR0, NA0, NW0
INTEGER :: IG, IG0
INTEGER , POINTER, DIMENSION (:) :: GHOST_PTR, WALL_PTR, NOM_PTR, EXT_PTR, CELLTYPE, A_SIZE, AUX
REAL(EB), POINTER, DIMENSION (:) :: MEASURE
REAL(EB), POINTER, DIMENSION (:) :: A , P , R, X
INTEGER,   POINTER, DIMENSION (:):: A_ROW, A_COL     
INTEGER,   POINTER, DIMENSION (:):: P_ROW, P_COL    
INTEGER,   POINTER, DIMENSION (:):: R_ROW, R_COL   
TYPE(SCARC_WALL_TYPE), POINTER, DIMENSION(:) :: WALL
END TYPE OSCARC_COMPACT_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! SCARC type for matrix stencil information
!!! offset in stencil, measure of cells, coarse and fine cells, couplings
!!!----------------------------------------------------------------------------------------------------
TYPE SCARC_PRECON_TYPE
REAL (EB), POINTER, DIMENSION (:)       :: MDX, LDX, UDX, MDY, MDZ, DWORK, PERIOD
REAL (EB), POINTER, DIMENSION (:, :, :) :: FFT
END TYPE SCARC_PRECON_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! SCARC types for different matrix storage technique 
!!!   - NX, NY, NZ : correspond to IBAR, JBAR, KBAR
!!!   - NC, NCE    : number of cells and cells_extended (including ghost cells)
!!!   - NW, NG     : number of wall and ghost cells
!!!   - NA, NP, NR : number of matrix entries in A, P and R
!!!   - NCPL       : number of couplings in matrix stencil on finest level (2D: 5, 3D: 7)
!!!   - NCC, NCF   : number of coarse and fine cells (only used in AMG)
!!!----------------------------------------------------------------------------------------------------
!!! Banded storage technique 
TYPE SCARC_BANDED_TYPE

INTEGER :: SUBDIVISION(3,-3:3)
INTEGER  , POINTER, DIMENSION (:, :, :) :: CELLTYPE
REAL (EB), POINTER, DIMENSION (:, :)    :: A
REAL (EB), POINTER, DIMENSION (:, :, :) :: X , F , D , Y , G , W, Z
REAL (EB), POINTER, DIMENSION (:, :, :) :: X2, F2, D2, Y2, G2, W2, Z2
INTEGER   :: NX, NY, NZ, NW
INTEGER   :: NC, NG, NCG, NCE
INTEGER   :: NA, NCPL, NAE
INTEGER   :: NLAYER
REAL(EB)  :: DXI, DYI, DZI, DXI2, DYI2, DZI2, DI2(3)

TYPE (SCARC_WALL_TYPE), POINTER, DIMENSION(:) :: WALL

END TYPE SCARC_BANDED_TYPE


!!! Compact storage technique 
TYPE SCARC_COMPACT_TYPE

INTEGER :: SUBDIVISION(3,-3:3)
INTEGER,   POINTER, DIMENSION (:)    :: INTERNAL_BDRY_CELL
INTEGER,   POINTER, DIMENSION (:, :) :: WC_INDEX, P_PTR, W_PTR
INTEGER,   POINTER, DIMENSION (:)    :: CELLTYPE, GHOST_PTR, WALL_PTR, EXT_PTR
REAL(EB),  POINTER, DIMENSION (:)    :: MEASURE
INTEGER,   POINTER, DIMENSION (:)    :: A_ROW, A_COL      ! row and column pointers for system matrix A
INTEGER,   POINTER, DIMENSION (:)    :: P_ROW, P_COL      ! row and column pointers for prolongation matrix P
INTEGER,   POINTER, DIMENSION (:)    :: R_ROW, R_COL      ! row and column pointers for restriction matrix A
REAL (EB), POINTER, DIMENSION (:)    :: A , P , R
REAL (EB), POINTER, DIMENSION (:)    :: X , F , D , Y , G , W, Z
REAL (EB), POINTER, DIMENSION (:)    :: X2, F2, D2, Y2, G2, W2, Z2
INTEGER   :: NX, NY, NZ, NW, NG, NW0
INTEGER   :: NC, NCG, NCE
INTEGER   :: NA, NCPL, NAE
INTEGER   :: NCC, NCCE, NCCP
INTEGER   :: NCF, NCFE, NCW
INTEGER   :: NP, NPE, NR, NRE
INTEGER   :: NLAYER, NCE0, NROW0, NCCI
REAL(EB)  :: DXI, DYI, DZI, DXI2, DYI2, DZI2, DI2(3)

TYPE (SCARC_WALL_TYPE), POINTER, DIMENSION(:) :: WALL

END TYPE SCARC_COMPACT_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! Wall type
!!!----------------------------------------------------------------------------------------------------
TYPE SCARC_WALL_TYPE
INTEGER, POINTER, DIMENSION (:) :: ICG, ICG2
INTEGER, POINTER, DIMENSION (:) :: ICN, ICN2
INTEGER, POINTER, DIMENSION (:) :: ICE, ICE2
INTEGER :: ICW, ICW2
INTEGER :: IXG, IYG, IZG
INTEGER :: IXW , IYW , IZW
INTEGER :: IXN1 , IYN1 , IZN1
INTEGER :: IXN2 , IYN2 , IZN2
INTEGER :: IOR, NOM
INTEGER :: NCPL, BTYPE
END TYPE SCARC_WALL_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! General ScaRC type with pointers to different structures on all grid levels
!!!----------------------------------------------------------------------------------------------------
TYPE SCARC_TYPE

INTEGER :: CYCLE_COUNT(2, NSCARC_LEVEL_MAX) = 0
REAL (EB), POINTER, DIMENSION (:,:) :: A_COARSE
REAL (EB), POINTER, DIMENSION (:)   :: X_COARSE, X_BUF
INTEGER  , POINTER, DIMENSION (:,:) :: PIVOT
INTEGER  , POINTER, DIMENSION (:)   :: OFFSET, COUNTS1, COUNTS2, DISPLS1, DISPLS2

TYPE (SCARC_PRECON_TYPE), POINTER, DIMENSION(:) :: PRECON

TYPE (SCARC_BANDED_TYPE) , POINTER, DIMENSION(:) :: BANDED
TYPE (SCARC_COMPACT_TYPE), POINTER, DIMENSION(:) :: COMPACT

TYPE (OSCARC_TYPE), POINTER, DIMENSION(:) :: OSCARC

END TYPE SCARC_TYPE


!!!----------------------------------------------------------------------------------------------------
!!! General OSCARC type on other mesh with mesh and exchange structures
!!!----------------------------------------------------------------------------------------------------
TYPE OSCARC_TYPE

REAL (EB), POINTER, DIMENSION (:) :: SEND_REAL, RECV_REAL
INTEGER  , POINTER, DIMENSION (:) :: SEND_INT , RECV_INT 
INTEGER :: NICMAX_R=0, NICMAX_S=0
INTEGER :: I_MIN_R=-10,I_MAX_R=-10,J_MIN_R=-10,J_MAX_R=-10,K_MIN_R=-10,K_MAX_R=-10,NIC_R=0, &
           I_MIN_S=-10,I_MAX_S=-10,J_MIN_S=-10,J_MAX_S=-10,K_MIN_S=-10,K_MAX_S=-10,NIC_S=0

TYPE (OSCARC_BANDED_TYPE) , POINTER, DIMENSION(:) :: BANDED
TYPE (OSCARC_COMPACT_TYPE), POINTER, DIMENSION(:) :: COMPACT

END TYPE OSCARC_TYPE


!!! globally used types
TYPE ( SCARC_TYPE), SAVE, DIMENSION(:), ALLOCATABLE, TARGET ::  SCARC
TYPE (OSCARC_TYPE), SAVE, DIMENSION(:), ALLOCATABLE, TARGET :: OSCARC


CONTAINS
 
 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! SCARC_SETUP : Initialize ScaRC structures 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP
INTEGER :: IERR
REAL(EB):: TNOW_SETUP

!!!----------------------------------------------------------------------------------------------------
!!! Initialize time measurement 
!!!----------------------------------------------------------------------------------------------------
IERR = 0
TNOW_SETUP = SECOND()

ALLOCATE(TUSED_SCARC(0:N_TIMERS_SCARC,NMESHES),STAT=IERR)
CALL ChkMemErr('SCARC_SETUP','TUSED_SCARC',IERR)

TUSED_SCARC = 0._EB
TUSED_SCARC(NSCARC_TIME_TOTAL,:) = SECOND()


!!!----------------------------------------------------------------------------------------------------
!!! Parse input parameters
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_INPUT_PARSER               ! parse input parameters (corresponding to FDS-file)


!!!----------------------------------------------------------------------------------------------------
!!! Setup different components of ScaRC 
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_SETUP_DIMENSION            ! define dimension of underlying problem
CALL SCARC_SETUP_DEBUGGING            ! open debug file if requested
CALL SCARC_SETUP_PROCESSES            ! determine set of meshes which must be processed on MYID
CALL SCARC_SETUP_LEVELS               ! define number of necessary grid levels 
CALL SCARC_SETUP_STRUCTURES           ! allocate requested ScaRC-types for all necessary grid levels
CALL SCARC_SETUP_MESHES               ! set mesh information
CALL SCARC_SETUP_EXCHANGE             ! set information for data exchange
CALL SCARC_SETUP_WALLINFO             ! set wall cell information
CALL SCARC_SETUP_SYSTEM               ! assemble system matrix with boundary conditions and solver vectors
CALL SCARC_SETUP_COARSENING           ! perform coarsening on different grid levels if requested (AMG only)
CALL SCARC_SETUP_VECTORS              ! allocate solution and auxiliary vectors on all needed grid levels
CALL SCARC_SETUP_GLOBALS              ! define some global variables
!CALL SCARC_SETUP_NEIGHBORS            ! compute information about abutting neighbors on coarser levels


!!!----------------------------------------------------------------------------------------------------
!!! Measure time for setup routine
!!!----------------------------------------------------------------------------------------------------
TUSED_SCARC(NSCARC_TIME_SETUP,:)=TUSED_SCARC(NSCARC_TIME_SETUP,:)+SECOND()-TNOW_SETUP
TUSED_SCARC(NSCARC_TIME_TOTAL,:)=TUSED_SCARC(NSCARC_TIME_TOTAL,:)+SECOND()-TNOW_SETUP

END SUBROUTINE SCARC_SETUP


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Define dimension of problem
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_DIMENSION
IF (TWO_D) THEN
   TYPE_DIMENSION = NSCARC_DIMENSION_TWO
ELSE
   TYPE_DIMENSION = NSCARC_DIMENSION_THREE
ENDIF
END SUBROUTINE SCARC_SETUP_DIMENSION


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine types of input parameters
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_INPUT_PARSER
CHARACTER(300):: CMESSAGE

!!!----------------------------------------------------------------------------------------------------
!!! set type of global solver
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TRIM(SCARC_METHOD))

   CASE ('KRYLOV')           

      TYPE_METHOD  = NSCARC_METHOD_KRYLOV
      TYPE_METHOD0 = NSCARC_METHOD_KRYLOV

      !!! set type of Krylov-method (CG/BICG)
      SELECT CASE (TRIM(SCARC_KRYLOV))
         CASE ('CG')
            TYPE_KRYLOV = NSCARC_KRYLOV_CG
         CASE ('BICG')
            TYPE_KRYLOV = NSCARC_KRYLOV_BICG
         CASE DEFAULT
            WRITE(CMESSAGE,1002) 'Krylov-solver',TRIM(SCARC_KRYLOV),'ScaRC','CG','BICG'
            CALL SCARC_SHUTDOWN(CMESSAGE)
      END SELECT 

      !!! set type of preconditioner (JACOBI/SSOR/GSTRIX/MG)
      SELECT CASE (TRIM(SCARC_PRECON))
         CASE ('JACOBI')
            TYPE_PRECON = NSCARC_PRECON_JACOBI
         CASE ('SSOR')
            TYPE_PRECON = NSCARC_PRECON_SSOR
         CASE ('GSTRIX')
            TYPE_PRECON = NSCARC_PRECON_GSTRIX
         CASE ('MULTIGRID')
            TYPE_PRECON = NSCARC_PRECON_MULTIGRID
            SELECT CASE (TRIM(SCARC_SMOOTH))
               CASE ('JACOBI')
                  TYPE_SMOOTH = NSCARC_SMOOTH_JACOBI
               CASE ('SSOR')
                  TYPE_SMOOTH = NSCARC_SMOOTH_SSOR
               CASE ('FFT')
                  TYPE_PRECON = NSCARC_SMOOTH_FFT
            END SELECT
         CASE ('FFT')
            TYPE_PRECON = NSCARC_PRECON_FFT
         CASE DEFAULT
            WRITE(CMESSAGE,1005) 'preconditioner',TRIM(SCARC_PRECON),&
                                 'Krylov-method','JACOBI','SSOR','GSTRIX','MG','FFT'
            CALL SCARC_SHUTDOWN(CMESSAGE)
      END SELECT
      TYPE_PRECON0 = TYPE_PRECON

   CASE ('MULTIGRID')

      TYPE_METHOD  = NSCARC_METHOD_MULTIGRID
      TYPE_METHOD0 = NSCARC_METHOD_MULTIGRID

      !!! set type of multigrid method (GEOMETRIC/ALGEBRAIC)
      SELECT CASE (TRIM(SCARC_MULTIGRID))
         CASE ('GEOMETRIC')
            TYPE_MULTIGRID = NSCARC_MULTIGRID_GEOMETRIC
         CASE ('ALGEBRAIC')
            TYPE_MULTIGRID = NSCARC_MULTIGRID_ALGEBRAIC
         CASE DEFAULT
            WRITE(CMESSAGE,1002) 'multigrid',TRIM(SCARC_MULTIGRID),&
                                 'ScaRC','GEOMETRIC','ALGEBRAIC'
            CALL SCARC_SHUTDOWN(CMESSAGE)
      END SELECT 

      !!! set type of multigrid method (GEOMETRIC/ALGEBRAIC)
      SELECT CASE (TRIM(SCARC_COARSE))
         CASE ('ITERATIVE')
            TYPE_COARSE = NSCARC_COARSE_ITERATIVE
            TYPE_KRYLOV = NSCARC_KRYLOV_CG
         CASE ('DIRECT')
            TYPE_COARSE = NSCARC_COARSE_DIRECT
            TYPE_DIRECT = NSCARC_DIRECT_GE
      END SELECT 

      !!! set type of smoother (JACOBI/SSOR/GSTRIX)
      SELECT CASE (TRIM(SCARC_SMOOTH))                          ! use same parameters as for preconditioner
         CASE ('JACOBI')
            TYPE_PRECON = NSCARC_PRECON_JACOBI
            TYPE_SMOOTH = NSCARC_SMOOTH_JACOBI
         CASE ('SSOR')
            TYPE_PRECON = NSCARC_PRECON_SSOR
            TYPE_SMOOTH = NSCARC_SMOOTH_SSOR
         CASE ('GSTRIX')
            TYPE_PRECON = NSCARC_PRECON_GSTRIX
            TYPE_SMOOTH = NSCARC_SMOOTH_GSTRIX
         CASE DEFAULT
            WRITE(CMESSAGE,1003) 'smoother',TRIM(SCARC_SMOOTH),'multigrid','JACOBI','SSOR','GSTRIX'
            CALL SCARC_SHUTDOWN(CMESSAGE)
      END SELECT

   CASE DEFAULT
      WRITE(CMESSAGE,1002) 'solver',TRIM(SCARC_METHOD),'ScaRC','KRYLOV','MULTIGRID'
      CALL SCARC_SHUTDOWN(CMESSAGE)

END SELECT 

!!!----------------------------------------------------------------------------------------------------
!!! if a multigrid solver is used (either as main solver or as preconditioner)
!!! set types for multigrid, coarse grid solver and cycling pattern
!!!----------------------------------------------------------------------------------------------------
IF (TYPE_METHOD == NSCARC_METHOD_MULTIGRID .OR. TYPE_PRECON == NSCARC_PRECON_MULTIGRID) THEN

   !!! set type of multigrid (GEOMETRIC/ALGEBRAIC with corresponding coarsening strategy)
   SELECT CASE (TRIM(SCARC_MULTIGRID))

      CASE ('GEOMETRIC')
         TYPE_MULTIGRID = NSCARC_MULTIGRID_GEOMETRIC

      CASE ('ALGEBRAIC')
         TYPE_MULTIGRID = NSCARC_MULTIGRID_ALGEBRAIC

         !!! set type of coarsening strategy (STANDARD/AGGRESSIVE)
         SELECT CASE (TRIM(SCARC_MULTIGRID_COARSENING))
            CASE ('RS3')
               TYPE_COARSENING = NSCARC_COARSENING_RS3
               TYPE_LAYER      = NSCARC_LAYER_ONE
            CASE ('A1')
               TYPE_COARSENING = NSCARC_COARSENING_A1
               TYPE_LAYER      = NSCARC_LAYER_ONE
            CASE ('A2')
               TYPE_COARSENING = NSCARC_COARSENING_A2
               TYPE_LAYER      = NSCARC_LAYER_ONE
            CASE ('PMIS')
               TYPE_COARSENING = NSCARC_COARSENING_PMIS
               TYPE_LAYER      = NSCARC_LAYER_TWO
            CASE ('PMISG')
               TYPE_COARSENING = NSCARC_COARSENING_PMISG
               TYPE_LAYER      = NSCARC_LAYER_TWO
            CASE ('FDSRS3')
               TYPE_COARSENING = NSCARC_COARSENING_FDSRS3
               TYPE_LAYER      = NSCARC_LAYER_ONE
            CASE ('FDSA1')
               TYPE_COARSENING = NSCARC_COARSENING_FDSA1
               TYPE_LAYER      = NSCARC_LAYER_TWO
            CASE ('FDSA2')
               TYPE_COARSENING = NSCARC_COARSENING_FDSA2
               TYPE_LAYER      = NSCARC_LAYER_TWO
            CASE ('BDRY')
               TYPE_COARSENING = NSCARC_COARSENING_BDRY
               TYPE_LAYER      = NSCARC_LAYER_TWO
            CASE DEFAULT
               WRITE(CMESSAGE,1005) 'coarsening',TRIM(SCARC_MULTIGRID_COARSENING),&
                                    'algebraic multigrid','RS3'   ,'A1'   ,'A2'   ,'PMIS',&
                                                          'PMISG','TEST','FDSA2','FDSRS3'
               CALL SCARC_SHUTDOWN(CMESSAGE)
         END SELECT

      CASE DEFAULT
         WRITE(CMESSAGE,1002) 'multigrid',TRIM(SCARC_MULTIGRID),&
                              'Krylov-preconditioner','GEOMETRIC','ALGEBRAIC'
         CALL SCARC_SHUTDOWN(CMESSAGE)
   END SELECT

   !!! set type of coarse grid solver (CG/GE)
   SELECT CASE (TRIM(SCARC_COARSE))
      CASE ('ITERATIVE')
         TYPE_COARSE = NSCARC_COARSE_ITERATIVE
         TYPE_KRYLOV = NSCARC_KRYLOV_CG
      CASE ('DIRECT')
         TYPE_COARSE = NSCARC_COARSE_DIRECT
         TYPE_DIRECT = NSCARC_DIRECT_GE
      CASE DEFAULT
         WRITE(CMESSAGE,1002) 'coarse grid solver',TRIM(SCARC_COARSE),'multigrid','ITERATIVE','DIRECT'
         CALL SCARC_SHUTDOWN(CMESSAGE)
   END SELECT

   !!! set type of cycling pattern (F/V/W)
   SELECT CASE (TRIM(SCARC_MULTIGRID_CYCLE))
      CASE ('F')
         TYPE_CYCLE = NSCARC_CYCLE_F
      CASE ('V')
         TYPE_CYCLE = NSCARC_CYCLE_V
      CASE ('W')
         TYPE_CYCLE = NSCARC_CYCLE_W
      CASE DEFAULT
         WRITE(CMESSAGE,1003) 'cycling ',TRIM(SCARC_MULTIGRID_CYCLE),'multigrid','F','V','W'
         CALL SCARC_SHUTDOWN(CMESSAGE)
   END SELECT

   !!! set type of interpolation (STANDARD/DIRECT/MULTIPASS)
   SELECT CASE (TRIM(SCARC_MULTIGRID_INTERPOL))
      CASE ('STANDARD')
         TYPE_INTERPOL = NSCARC_INTERPOL_STANDARD
      CASE ('CLASSICAL')
         TYPE_INTERPOL = NSCARC_INTERPOL_CLASSICAL
      CASE ('DIRECT')
         TYPE_INTERPOL = NSCARC_INTERPOL_DIRECT
      CASE ('DIRECT_BDRY')
         TYPE_INTERPOL = NSCARC_INTERPOL_DIRECT_BDRY
      CASE ('MULTIPASS')
         TYPE_INTERPOL = NSCARC_INTERPOL_MULTIPASS
      CASE DEFAULT
         WRITE(CMESSAGE,1004) 'cycling ',TRIM(SCARC_MULTIGRID_INTERPOL), &
                              'multigrid','STANDARD','DIRECT','DIRECT_BDRY','MULTIPASS'
         CALL SCARC_SHUTDOWN(CMESSAGE)
   END SELECT

ENDIF

!!!----------------------------------------------------------------------------------------------------
!!! set storage type (BANDED/COMPACT)
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TRIM(SCARC_SYSTEM))
   CASE ('BANDED')
      IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN
         WRITE(CMESSAGE,2002) 'system',TRIM(SCARC_SYSTEM),'ScaRC','TYPE_MULTIGRID','ALGEBRAIC',&
                              'TYPE_SYSTEM','COMPACT'
         TYPE_SYSTEM = NSCARC_SYSTEM_COMPACT
      ELSE
         TYPE_SYSTEM = NSCARC_SYSTEM_BANDED
      ENDIF
   CASE ('COMPACT')
      TYPE_SYSTEM = NSCARC_SYSTEM_COMPACT
   CASE ('null')

      SELECT_METHOD: SELECT CASE (TYPE_METHOD)

         CASE (NSCARC_METHOD_KRYLOV)

            SELECT_PRECON: SELECT CASE (TYPE_PRECON)
               CASE (NSCARC_PRECON_MULTIGRID) 
                  IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_GEOMETRIC) THEN
                     TYPE_SYSTEM = NSCARC_SYSTEM_BANDED
                  ELSE
                     TYPE_SYSTEM = NSCARC_SYSTEM_COMPACT
                  ENDIF
               CASE DEFAULT
                  TYPE_SYSTEM = NSCARC_SYSTEM_BANDED
            END SELECT SELECT_PRECON

         CASE (NSCARC_METHOD_MULTIGRID)

            SELECT_MULTIGRID: SELECT CASE (TYPE_MULTIGRID)
               CASE (NSCARC_MULTIGRID_GEOMETRIC) 
                  TYPE_SYSTEM = NSCARC_SYSTEM_BANDED
               CASE (NSCARC_MULTIGRID_ALGEBRAIC) 
                  TYPE_SYSTEM = NSCARC_SYSTEM_COMPACT
            END SELECT SELECT_MULTIGRID

      END SELECT SELECT_METHOD

END SELECT


!!!----------------------------------------------------------------------------------------------------
!!! set type of accuracy (ABSOLUTE/RELATIVE)
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TRIM(SCARC_ACCURACY))
   CASE ('ABSOLUTE')
      TYPE_ACCURACY = NSCARC_ACCURACY_ABSOLUTE
   CASE ('RELATIVE')
      TYPE_ACCURACY = NSCARC_ACCURACY_RELATIVE
   CASE DEFAULT
      WRITE(CMESSAGE,1002) 'accuracy',TRIM(SCARC_ACCURACY),'ScaRC','ABSOLUTE','RELATIVE'
      CALL SCARC_SHUTDOWN(CMESSAGE)
END SELECT

!!!----------------------------------------------------------------------------------------------------
!!! set level of debugging (NONE/LESS/MEDIUM/MUCH)
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TRIM(SCARC_DEBUG))
   CASE ('NONE')
      TYPE_DEBUG = NSCARC_DEBUG_NONE
   CASE ('INFO0')
      TYPE_DEBUG = NSCARC_DEBUG_INFO0
   CASE ('INFO1')
      TYPE_DEBUG = NSCARC_DEBUG_INFO1
   CASE ('INFO2')
      TYPE_DEBUG = NSCARC_DEBUG_INFO2
   CASE ('LESS')
      TYPE_DEBUG = NSCARC_DEBUG_LESS
   CASE ('MEDIUM')
      TYPE_DEBUG = NSCARC_DEBUG_MEDIUM
   CASE ('MUCH')
      TYPE_DEBUG = NSCARC_DEBUG_MUCH
   CASE DEFAULT
      WRITE(CMESSAGE,1006) 'debugging',TRIM(SCARC_DEBUG),'ScaRC','NONE','INFO0','INFO1','INFO2','LESS','MEDIUM','MUCH'
      CALL SCARC_SHUTDOWN(CMESSAGE)
END SELECT

!!!----------------------------------------------------------------------------------------------------
!!! set type of initial solution (not yet used, may be used to define own initial vector)
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TRIM(SCARC_INITIAL))
   CASE ('null')
      TYPE_INITIAL = NSCARC_INITIAL_NONE
   CASE DEFAULT
      TYPE_INITIAL = NSCARC_INITIAL_NONE
END SELECT

1002 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, &
             'ScaRC: Possible choices are ',A,'\/',A,/,&
             'ScaRC: Aborting program ...')
1003 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, &
             'ScaRC: Possible choices are ',A,'\/',A,'\/',A,/,&
             'ScaRC: Aborting program ...')
1004 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, &
             'ScaRC: Possible choices are ',A,'\/',A,'\/',A,'\/',A,/,&
             'ScaRC: Aborting program ...')
1005 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, &
             'ScaRC: Possible choices are ',A,'\/',A,'\/',A,'\/',A,'\/',A,/,&
             'ScaRC: Aborting program ...')
1006 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, &
             'ScaRC: Possible choices are ',A,'\/',A,'\/',A,'\/',A,'\/',A,'\/',A,/,&
             'ScaRC: Aborting program ...')
1007 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, &
             'ScaRC: Possible choices are ',A,'\/',A,'\/',A,'\/',A,'\/',A,'\/',A,'\/',A,/,&
             'ScaRC: Aborting program ...')
!1008 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, &
!             'ScaRC: Possible choices are ',A,'\/',A,'\/',A,'\/',A,'\/',A,'\/',A,'\/',A,'\/',A,/,&
!             'ScaRC: Aborting program ...')
2002 FORMAT ('ScaRC: Wrong ',A,' type ',A,' for ',A,/, ' in case of ',A,'=',A,/, &
             'ScaRC: Redefining ',A,' to ',A,' !',/)
END SUBROUTINE SCARC_INPUT_PARSER


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Setup debug file if requested
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_DEBUGGING
INTEGER:: NM

IF (TYPE_DEBUG > NSCARC_DEBUG_NONE) THEN
   IF (USE_MPI) THEN
      DO NM=1,NMESHES
         IF (PROCESS(NM)/=MYID) CYCLE
         WRITE (SCARC_FN, '(A,A,i3.3)') TRIM(CHID),'.scarc',MYID+1
         SCARC_LU = GET_FILE_NUMBER()
         OPEN (SCARC_LU, FILE=SCARC_FN)
      ENDDO
   ELSE
      WRITE (SCARC_FN, '(A,A,i3.3)') TRIM(CHID),'.scarc',MYID+1
      SCARC_LU = GET_FILE_NUMBER()
      OPEN (SCARC_LU, FILE=SCARC_FN)
   ENDIF
ENDIF

END SUBROUTINE SCARC_SETUP_DEBUGGING


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Serial or parallel version ? Decide which meshes must be processed
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_PROCESSES
IF (USE_MPI) THEN
   NMESHES_MIN = MYID+1
   NMESHES_MAX = MYID+1
ELSE
   NMESHES_MIN = 1
   NMESHES_MAX = NMESHES
ENDIF
END SUBROUTINE SCARC_SETUP_PROCESSES

 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine number of grid levels  (1 for CG/BICG-method, NLEVEL for MG-method)
!!! Note: NLEVEL_MIN corresponds to finest grid resolution, NLEVEL_MAX to coarsest resolution
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_LEVELS
INTEGER :: KLEVEL(3), KLEVEL_MIN, NM

SELECT CASE (TYPE_MULTIGRID)

   !!!------------------------------------------------------------------------------------------------------
   !!! predefined hierarchy of levels in case of geometric multigrid-method
   !!!------------------------------------------------------------------------------------------------------
   CASE (NSCARC_MULTIGRID_GEOMETRIC)

      NLEVEL = NSCARC_LEVEL_MAX
      KLEVEL = NSCARC_LEVEL_MAX

      DO NM=1,NMESHES

         KLEVEL(1)=SCARC_GET_MAXLEVEL(MESHES(NM)%IBAR,1)
         IF (TYPE_DIMENSION == NSCARC_DIMENSION_THREE) KLEVEL(2)=SCARC_GET_MAXLEVEL(MESHES(NM)%JBAR,2)
         KLEVEL(3)=SCARC_GET_MAXLEVEL(MESHES(NM)%KBAR,3)

         KLEVEL_MIN = MINVAL(KLEVEL)
         IF (KLEVEL_MIN<NLEVEL) NLEVEL=KLEVEL_MIN

      ENDDO 
      NLEVEL_MIN  = 1
      IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_GEOMETRIC .AND. TYPE_COARSE == NSCARC_COARSE_DIRECT) THEN
         NLEVEL_MAX  = NLEVEL + 1
      ELSE IF (SCARC_MULTIGRID_LEVEL /= -1) THEN
         NLEVEL_MAX  = NLEVEL_MIN + SCARC_MULTIGRID_LEVEL - 1
      ELSE
         NLEVEL_MAX  = NLEVEL
      ENDIF
      NLEVEL = NLEVEL_MAX

   !!!------------------------------------------------------------------------------------------------------
   !!! first, only finest level is set, further levels are defined during coarsening process
   !!!------------------------------------------------------------------------------------------------------
   CASE (NSCARC_MULTIGRID_ALGEBRAIC)
 
      NLEVEL_MIN = 1
      IF (SCARC_MULTIGRID_LEVEL /= -1) THEN
         NLEVEL_MAX  = SCARC_MULTIGRID_LEVEL 
      ELSE
         NLEVEL_MAX  = NSCARC_LEVEL_MAX
      ENDIF
      NLEVEL = SCARC_MULTIGRID_LEVEL


   !!!------------------------------------------------------------------------------------------------------
   !!! no multigrid-hierachy needed in case of a pure Krylov-method: use only one level
   !!!------------------------------------------------------------------------------------------------------
   CASE DEFAULT

      NLEVEL     = 1
      NLEVEL_MIN = 1
      NLEVEL_MAX = 1

END SELECT

END SUBROUTINE SCARC_SETUP_LEVELS


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine maximum number of possible levels on direction IOR0 of mesh NM
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
INTEGER FUNCTION SCARC_GET_MAXLEVEL(NC, IOR0)
INTEGER, INTENT(IN) :: NC, IOR0
INTEGER :: NC0, NL

!!! In case of the GMG-method, NC must be divisable by 2 at least one time 
IF (MOD(NC,2)/=0 .AND. TYPE_MULTIGRID == NSCARC_MULTIGRID_GEOMETRIC) THEN
   SELECT CASE (IOR0)
      CASE (1)
         WRITE(*,1000) 'IBAR', NC
      CASE (2)
         WRITE(*,1000) 'JBAR', NC
      CASE (3)
         WRITE(*,1000) 'KBAR', NC
   END SELECT
   STOP
ENDIF

!!! divide by 2 as often as possible or till user defined max-level is reached
NC0=NC
DO NL=1,NSCARC_LEVEL_MAX
   NC0=NC0/2
   IF (MOD(NC0,2)/=0) EXIT                  ! NC no longer divisable by two
   IF (NL==SCARC_MULTIGRID_LEVEL) EXIT      ! max number of levels defined by user
   IF (NC0==1) EXIT                         ! NC is power of two, minimum has been reached
ENDDO

SCARC_GET_MAXLEVEL=NL
RETURN
1000 FORMAT(A,'=',I3,' must be divisable by two for ScaRC-Multigrid!')
END FUNCTION SCARC_GET_MAXLEVEL


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Allocate ScaRC-structures for all needed levels
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_STRUCTURES
INTEGER :: IERR, NM
TYPE (SCARC_TYPE), POINTER :: S

!!! --------------------------------------------------------------------------------------------------------
!!! Allocate global ScaRC-structure
!!! --------------------------------------------------------------------------------------------------------
ALLOCATE (SCARC(NMESHES), STAT=IERR)
CALL CHKMEMERR ('SCARC_SETUP', 'SCARC', IERR)

!!! --------------------------------------------------------------------------------------------------------
!!! Allocate local OSCARC, MESHES, SYSTEM (COMPACT/BANDED) and PRECON structures for single meshes
!!! --------------------------------------------------------------------------------------------------------
MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

   S => SCARC(NM)

   ALLOCATE (S%OSCARC(NMESHES), STAT=IERR)
   CALL CHKMEMERR ('SCARC_SETUP_STRUCTURES', 'OSCARC', IERR)
      
   SELECT CASE (TYPE_SYSTEM)
      CASE (NSCARC_SYSTEM_BANDED)
         ALLOCATE (SCARC(NM)%BANDED(NLEVEL_MIN:NLEVEL_MAX), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_STRUCTURES', 'BANDED', IERR)
      CASE (NSCARC_SYSTEM_COMPACT)
         ALLOCATE (SCARC(NM)%COMPACT(NLEVEL_MIN:NLEVEL_MAX), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_STRUCTURES', 'COMPACT', IERR)
   END SELECT

   IF (TYPE_PRECON == NSCARC_PRECON_FFT .OR. TYPE_PRECON == NSCARC_PRECON_GSTRIX) THEN
      ALLOCATE (SCARC(NM)%PRECON(NLEVEL_MIN:NLEVEL_MAX), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_STRUCTURES', 'PRECON', IERR)
   ENDIF

ENDDO MESHES_LOOP

END SUBROUTINE SCARC_SETUP_STRUCTURES


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Setup geometry information for mesh NM
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_MESHES
INTEGER  :: IERR, NL, NM
INTEGER  :: NX0, NY0, NZ0
TYPE (MESH_TYPE)         , POINTER :: M
TYPE (SCARC_TYPE)        , POINTER :: S
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

IERR=0

SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)
 
   !!!-------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)
      
      BANDED_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         M => MESHES(NM)
         S => SCARC(NM)
         
         !!!
         !!!  define hierarchy of meshes depending on the chosen method
         !!!
         NX0=MESHES(NM)%IBAR
         NY0=MESHES(NM)%JBAR
         NZ0=MESHES(NM)%KBAR
         
         BANDED_LEVEL_LOOP: DO NL = NLEVEL_MIN, NLEVEL_MAX
         
            IF (NL > NLEVEL_MIN .AND. TYPE_MULTIGRID /= NSCARC_MULTIGRID_GEOMETRIC) EXIT BANDED_LEVEL_LOOP

            !!! let SM point to SCARC(NM)%MESHES(NL)
            SB => S%BANDED(NL)
            
            !!! numbers of cells in x-, y- and z-direction for level 'NL'
            SB%NX = NX0
            SB%NY = NY0
            SB%NZ = NZ0
            
            !!! step widths in x-, y- and z-direction for level 'NL'
            SB%DXI = REAL(SB%NX,EB)/(M%XF-M%XS)
            SB%DYI = REAL(SB%NY,EB)/(M%YF-M%YS)
            SB%DZI = REAL(SB%NZ,EB)/(M%ZF-M%ZS)
            
            SB%DXI2 = SB%DXI**2
            SB%DYI2 = SB%DYI**2
            SB%DZI2 = SB%DZI**2
          
            SB%DI2(1) = SB%DXI2
            SB%DI2(2) = SB%DYI2
            SB%DI2(3) = SB%DZI2

            !!! Get global number of grid cells (internal and including ghost cells)
            SB%NC  = SB%NX * SB%NY * SB%NZ 
            SELECT CASE (TYPE_DIMENSION)
               CASE (NSCARC_DIMENSION_TWO)
                  SB%NCG = (SB%NX+2) * (SB%NZ+2) 
               CASE (NSCARC_DIMENSION_THREE)
                  SB%NCG = (SB%NX+2) * (SB%NY+2) * (SB%NZ+2) 
            END SELECT
             
            NX0=NX0/2
            IF (TYPE_DIMENSION == NSCARC_DIMENSION_THREE) NY0=NY0/2
            NZ0=NZ0/2
         
         ENDDO BANDED_LEVEL_LOOP

      ENDDO BANDED_MESHES_LOOP
      
   !!!-------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      COMPACT_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         M => MESHES(NM)
         S => SCARC(NM)
         
         !!!
         !!!  define hierarchy of meshes depending on the chosen method
         !!!
         NX0=MESHES(NM)%IBAR
         NY0=MESHES(NM)%JBAR
         NZ0=MESHES(NM)%KBAR
         
         COMPACT_LEVEL_LOOP: DO NL = NLEVEL_MIN, NLEVEL_MAX
         
            IF (NL > NLEVEL_MIN .AND. TYPE_MULTIGRID /= NSCARC_MULTIGRID_GEOMETRIC) EXIT COMPACT_LEVEL_LOOP

            !!! let SM point to SCARC(NM)%MESHES(NL)
            SC => S%COMPACT(NL)
            
            !!! numbers of cells in x-, y- and z-direction for level 'NL'
            SC%NX = NX0
            SC%NY = NY0
            SC%NZ = NZ0
            
            !!! step widths in x-, y- and z-direction for level 'NL'
            SC%DXI = REAL(SC%NX,EB)/(M%XF-M%XS)
            SC%DYI = REAL(SC%NY,EB)/(M%YF-M%YS)
            SC%DZI = REAL(SC%NZ,EB)/(M%ZF-M%ZS)
            
            SC%DXI2 = SC%DXI**2
            SC%DYI2 = SC%DYI**2
            SC%DZI2 = SC%DZI**2
          
            SC%DI2(1) = SC%DXI2
            SC%DI2(2) = SC%DYI2
            SC%DI2(3) = SC%DZI2

            !!! Get global number of grid cells (internal and including ghost cells)
            SC%NC  = SC%NX * SC%NY * SC%NZ 
            SELECT CASE (TYPE_DIMENSION)
               CASE (NSCARC_DIMENSION_TWO)
                  SC%NCG = (SC%NX+2) * (SC%NZ+2) 
               CASE (NSCARC_DIMENSION_THREE)
                  SC%NCG = (SC%NX+2) * (SC%NY+2) * (SC%NZ+2) 
            END SELECT
             
            NX0=NX0/2
            IF (TYPE_DIMENSION == NSCARC_DIMENSION_THREE) NY0=NY0/2
            NZ0=NZ0/2
         
         ENDDO COMPACT_LEVEL_LOOP

      ENDDO COMPACT_MESHES_LOOP

END SELECT SELECT_SYSTEM

END SUBROUTINE SCARC_SETUP_MESHES
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Setup communication structure for data exchange 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_EXCHANGE 
INTEGER :: NOM, NM, NL, N
INTEGER :: IERR, IW
TYPE (MESH_TYPE)          , POINTER :: M
TYPE (SCARC_TYPE)         , POINTER :: S
TYPE (OMESH_TYPE)         , POINTER :: OM
TYPE (OSCARC_TYPE)        , POINTER :: OS
TYPE (OSCARC_BANDED_TYPE) , POINTER :: OSBF, OSBC
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSCF, OSCC

IERR = 0

!!! Initialize communication counter for ScaRC, use same TAG for all communications
N_EXCHANGES = 0
TAG_SCARC  = 99

!!!----------------------------------------------------------------------------------------------------
!!! Store communication counters from FDS-code
!!!----------------------------------------------------------------------------------------------------
MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
   
   M => MESHES(NM)
   S => SCARC(NM)
   
   !!! Initialize level structures on neighboring meshes
   OTHER_MESHES_LOOP: DO NOM = 1, NMESHES
      
      IF (NOM == NM) CYCLE OTHER_MESHES_LOOP
   
      OM => M%OMESH(NOM)
      OS => S%OSCARC(NOM)
   
      OS%I_MIN_S  = OM%I_MIN_S
      OS%I_MAX_S  = OM%I_MAX_S
      OS%J_MIN_S  = OM%J_MIN_S
      OS%J_MAX_S  = OM%J_MAX_S
      OS%K_MIN_S  = OM%K_MIN_S
      OS%K_MAX_S  = OM%K_MAX_S
      OS%NIC_S    = OM%NIC_S
      OS%NICMAX_S = OM%NIC_S
       
      OS%I_MIN_R  = OM%I_MIN_R
      OS%I_MAX_R  = OM%I_MAX_R
      OS%J_MIN_R  = OM%J_MIN_R
      OS%J_MAX_R  = OM%J_MAX_R
      OS%K_MIN_R  = OM%K_MIN_R
      OS%K_MAX_R  = OM%K_MAX_R
      OS%NIC_R    = OM%NIC_R
      OS%NICMAX_R = OM%NIC_R
   
      IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0)  CYCLE OTHER_MESHES_LOOP

      N_EXCHANGES  = N_EXCHANGES+1
   
   ENDDO OTHER_MESHES_LOOP
ENDDO MESHES_LOOP

SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

   !!!-------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      BANDED_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
         
         M => MESHES(NM)
         S => SCARC(NM)
         
         !!! Initialize level structures on neighboring meshes
         BANDED_OTHER_MESHES_LOOP: DO NOM = 1, NMESHES
            
            IF (NOM == NM) CYCLE BANDED_OTHER_MESHES_LOOP

            OS => S%OSCARC(NOM)
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0)  CYCLE BANDED_OTHER_MESHES_LOOP
         
            !!! Allocate OSCARC grid structure for mesh NM
            ALLOCATE (S%OSCARC(NOM)%BANDED(NLEVEL_MIN:NLEVEL_MAX), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_EXCHANGE', 'OS%BANDED', IERR)
         
            !!! point to grid structure of OSCARC(NM) on finest level
            OSBF => S%OSCARC(NOM)%BANDED(NLEVEL_MIN)

            OSBF%NX =  MESHES(NOM)%IBAR 
            OSBF%NY =  MESHES(NOM)%JBAR 
            OSBF%NZ =  MESHES(NOM)%KBAR 

            OSBF%NW = 2*OSBF%NX*OSBF%NY + 2*OSBF%NX*OSBF%NZ + 2*OSBF%NY*OSBF%NZ  
            OSBF%NG = 0
            OSBF%NA = 0
         
            IF (S%OSCARC(NOM)%NICMAX_S == 0 .AND. S%OSCARC(NOM)%NICMAX_R == 0) CYCLE BANDED_OTHER_MESHES_LOOP

            !!! Allocate OSCARC grid structure for mesh NM
            ALLOCATE (OSBF%WALL(OSBF%NW), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_EXCHANGE', 'OSBF%WALL', IERR)


            DO IW = 1, OSBF%NW

               OSBF%WALL(IW)%IXG = M%OMESH(NOM)%IJKW(1,IW)
               OSBF%WALL(IW)%IYG = M%OMESH(NOM)%IJKW(2,IW)
               OSBF%WALL(IW)%IZG = M%OMESH(NOM)%IJKW(3,IW)

               OSBF%WALL(IW)%IXW  = M%OMESH(NOM)%IJKW(6,IW)
               OSBF%WALL(IW)%IYW  = M%OMESH(NOM)%IJKW(7,IW)
               OSBF%WALL(IW)%IZW  = M%OMESH(NOM)%IJKW(8,IW)

               OSBF%WALL(IW)%IXN1  = M%OMESH(NOM)%IJKW(10,IW)
               OSBF%WALL(IW)%IXN2  = M%OMESH(NOM)%IJKW(13,IW)
               OSBF%WALL(IW)%IYN1  = M%OMESH(NOM)%IJKW(11,IW)
               OSBF%WALL(IW)%IYN2  = M%OMESH(NOM)%IJKW(14,IW)
               OSBF%WALL(IW)%IZN1  = M%OMESH(NOM)%IJKW(12,IW)
               OSBF%WALL(IW)%IZN2  = M%OMESH(NOM)%IJKW(15,IW)

               OSBF%WALL(IW)%IOR      = M%OMESH(NOM)%IJKW(4,IW)
               OSBF%WALL(IW)%NOM      = M%OMESH(NOM)%IJKW(9,IW)
            ENDDO


            !!! In case of GMG with a predefined grid hierarchy allocate corresponding level-structures
            IF (NLEVEL_MAX > NLEVEL_MIN .AND. TYPE_MULTIGRID==NSCARC_MULTIGRID_GEOMETRIC) THEN                   
               DO NL=NLEVEL_MIN+1,NLEVEL_MAX
         
                  OSBC => S%OSCARC(NOM)%BANDED(NL)                            ! pointer to coarser level
                  OSBF => S%OSCARC(NOM)%BANDED(NL-1)                          ! pointer to finer level
         
                  ! get number of internal cells and external wall cells on neighbor NOM for level NL
                  OSBC%NX=OSBF%NX/2
                  SELECT CASE (TYPE_DIMENSION)
                     CASE (NSCARC_DIMENSION_TWO)
                        OSBC%NY=1
                     CASE (NSCARC_DIMENSION_THREE)
                        OSBC%NY=OSBF%NY/2
                  END SELECT
                  OSBC%NZ=OSBF%NZ/2
         
                  OSBC%NC = OSBC%NX * OSBC%NY * OSBC%NZ
                  OSBC%NW = 2*OSBC%NX*OSBC%NY + 2*OSBC%NX*OSBC%NZ + 2*OSBC%NY*OSBC%NZ  
         
                  !!! Allocate OSCARC grid structure for mesh NM
                  ALLOCATE (OSBC%WALL(OSBC%NW), STAT=IERR)
                  CALL CHKMEMERR ('SCARC_SETUP_EXCHANGE', 'OSBC%WALL', IERR)

               ENDDO
            ENDIF
               
         ENDDO BANDED_OTHER_MESHES_LOOP
      ENDDO BANDED_MESHES_LOOP
   
   !!!-------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      COMPACT_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
         
         M => MESHES(NM)
         S => SCARC(NM)
         
         !!! Initialize level structures on neighboring meshes
         COMPACT_OTHER_MESHES_LOOP: DO NOM = 1, NMESHES
            
            IF (NOM == NM) CYCLE COMPACT_OTHER_MESHES_LOOP

            OS => S%OSCARC(NOM)
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0)  CYCLE COMPACT_OTHER_MESHES_LOOP

            !!! Allocate OSCARC grid structure for mesh NM
            ALLOCATE (S%OSCARC(NOM)%COMPACT(NLEVEL_MIN:NLEVEL_MAX), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_EXCHANGE', 'OS%COMPACT', IERR)
         
            !!! point to grid structure of OSCARC(NM) on finest level
            OSCF => S%OSCARC(NOM)%COMPACT(NLEVEL_MIN)

            OSCF%NX = MESHES(NOM)%IBAR 
            OSCF%NY = MESHES(NOM)%JBAR 
            OSCF%NZ = MESHES(NOM)%KBAR 

            OSCF%NW = 2*OSCF%NX*OSCF%NY + 2*OSCF%NX*OSCF%NZ + 2*OSCF%NY*OSCF%NZ  
            OSCF%NC = OSCF%NX*OSCF%NY*OSCF%NZ 
            OSCF%NG = 0
            OSCF%NA = 0
         
!WRITE(SCARC_LU,*) 'SCARC(',NM,')%OSCARC(',NOM,')%NW=',OSCF%NW

            IF (S%OSCARC(NOM)%NICMAX_S == 0 .AND. S%OSCARC(NOM)%NICMAX_R == 0) CYCLE COMPACT_OTHER_MESHES_LOOP

            !!! Allocate OSCARC grid structure for mesh NM
            ALLOCATE (OSCF%WALL(OSCF%NW), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_EXCHANGE', 'OSCF%WALL', IERR)

            !!! In case of GMG with a predefined grid hierarchy allocate corresponding level-structures
            IF (NLEVEL_MAX > NLEVEL_MIN .AND. TYPE_MULTIGRID==NSCARC_MULTIGRID_GEOMETRIC) THEN                   
               DO NL=NLEVEL_MIN+1,NLEVEL_MAX
         
                  OSCC => S%OSCARC(NOM)%COMPACT(NL)                            ! pointer to coarser level
                  OSCF => S%OSCARC(NOM)%COMPACT(NL-1)                          ! pointer to finer level
         
                  ! get number of internal cells and external wall cells on neighbor NOM for level NL
                  OSCC%NX=OSCF%NX/2
                  SELECT CASE (TYPE_DIMENSION)
                     CASE (NSCARC_DIMENSION_TWO)
                        OSCC%NY=1
                     CASE (NSCARC_DIMENSION_THREE)
                        OSCC%NY=OSCF%NY/2
                  END SELECT
                  OSCC%NZ=OSCF%NZ/2
         
                  OSCC%NC=OSCC%NX * OSCC%NY * OSCC%NZ
                  OSCC%NW= 2*OSCC%NX*OSCC%NY + 2*OSCC%NX*OSCC%NZ + 2*OSCC%NY*OSCC%NZ  
         
                  !!! Allocate OSCARC grid structure for mesh NM
                  ALLOCATE (OSCC%WALL(OSCC%NW), STAT=IERR)
                  CALL CHKMEMERR ('SCARC_SETUP_EXCHANGE', 'OSCC%WALL', IERR)

               ENDDO
            ENDIF
               
         ENDDO COMPACT_OTHER_MESHES_LOOP
      ENDDO COMPACT_MESHES_LOOP
   
END SELECT SELECT_SYSTEM

!!!
!!! Allocate request array for data exchanges
!!!
IERR = 0
IF (NMESHES>1) THEN
   ALLOCATE (REQ_SCARC(N_EXCHANGES*40))
   CALL CHKMEMERR ('SCARC_SETUP_GLOBAL', 'REQ_SCARC', IERR)
   REQ_SCARC = MPI_REQUEST_NULL
ENDIF

!!!
!!! Allocate counter and displacement vector for global data exchanges
!!!
ALLOCATE(COUNTS_SCARC(0:NUMPROCS-1))
ALLOCATE(DISPLS_SCARC(0:NUMPROCS-1))

COUNTS_SCARC = 0
DO N=0,NUMPROCS-1
   DO NM=1,NMESHES
      IF (PROCESS(NM)==N) COUNTS_SCARC(N) = COUNTS_SCARC(N) + 1
   ENDDO
ENDDO
DISPLS_SCARC(0) = 0
DO N=1,NUMPROCS-1
   DISPLS_SCARC(N) = COUNTS_SCARC(N-1) + DISPLS_SCARC(N-1)
ENDDO


END SUBROUTINE SCARC_SETUP_EXCHANGE

 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Setup neighborship structures and boundary conditions on finest level
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_WALLINFO
USE GEOMETRY_FUNCTIONS, ONLY: SEARCH_OTHER_MESHES
INTEGER :: NM, NL, NOM, NLMIN, NLMAX
INTEGER :: IOFFSET, IXC, IYC, IZC, IWF, IWC, IREFINE, IERR, ICPL, NCPL
INTEGER :: IC, IX, IY, IZ, ICE, ICE2
INTEGER :: IOFX, IOFY, IOFZ, MLATEX
TYPE (MESH_TYPE) , POINTER :: M
TYPE (SCARC_TYPE), POINTER :: S
TYPE (OSCARC_TYPE), POINTER :: OS
TYPE (SCARC_BANDED_TYPE)  , POINTER :: SBF, SBC
TYPE (SCARC_COMPACT_TYPE) , POINTER :: SCF, SCC
TYPE (OSCARC_BANDED_TYPE) , POINTER :: OSBF
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSCF

IERR=0

SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)
 
   !!!----------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      MESHES_LOOP_BANDED: DO NM = NMESHES_MIN, NMESHES_MAX
      
         M => MESHES(NM)
         S => SCARC(NM)
            
         !!! For all solver: 
         !!! Determine array WALL structure and PRESSURE_BC_INDEX on finest level
         SBF => S%BANDED(NLEVEL_MIN)

         SBF%NW =  M%N_EXTERNAL_WALL_CELLS
         SBF%NCE = SBF%NC

         SBF%NLAYER = 1                   ! Krylov and GMG only: 1 layer for data exchange
         
         !!! cell numbers of ghost cells
         ALLOCATE(SBF%WALL(SBF%NW), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','WALL',IERR)

         DO IWF = 1, SBF%NW
      
            !!! -----------------------------------------------------------------------------
            !!! Determine boundary type for IWF
            !!! -----------------------------------------------------------------------------
            IF (M%WALL(IWF)%BOUNDARY_TYPE == OPEN_BOUNDARY) THEN
               SBF%WALL(IWF)%BTYPE = DIRICHLET
            ELSE IF (M%WALL(IWF)%NOM /= 0) THEN !****CHECK
               SBF%WALL(IWF)%BTYPE = INTERNAL
            !ELSE IF (M%BOUNDARY_TYPE(IWF) == NULL_BOUNDARY) THEN
            !   SBF%WALL(IWF)%BTYPE = DIRICHLET
            ELSE
               SBF%WALL(IWF)%BTYPE = NEUMANN
            ENDIF

            !!! -----------------------------------------------------------------------------
            !!! Determine wall and ghost cells and indices
            !!! -----------------------------------------------------------------------------
            SBF%WALL(IWF)%ICW = (M%WALL(IWF)%ONE_D%KKG-1)*M%IBAR*M%JBAR + &
                                (M%WALL(IWF)%ONE_D%JJG-1)*M%IBAR        + &
                                 M%WALL(IWF)%ONE_D%IIG

            SBF%WALL(IWF)%IXG =  M%WALL(IWF)%ONE_D%II
            SBF%WALL(IWF)%IYG =  M%WALL(IWF)%ONE_D%JJ
            SBF%WALL(IWF)%IZG =  M%WALL(IWF)%ONE_D%KK

            SBF%WALL(IWF)%IXW =  M%WALL(IWF)%ONE_D%IIG
            SBF%WALL(IWF)%IYW =  M%WALL(IWF)%ONE_D%JJG
            SBF%WALL(IWF)%IZW =  M%WALL(IWF)%ONE_D%KKG

            !!! -----------------------------------------------------------------------------
            !!! Determine neighbor and orientation
            !!! -----------------------------------------------------------------------------
            NOM = M%WALL(IWF)%NOM

            SBF%WALL(IWF)%NOM = NOM
            SBF%WALL(IWF)%IOR = M%WALL(IWF)%ONE_D%IOR


            !!! -----------------------------------------------------------------------------
            !!! Determine neighboring cells and indices which must be exchanged
            !!! -----------------------------------------------------------------------------
            IF (NOM /= 0) THEN

               OSBF => SCARC(NM)%OSCARC(NOM)%BANDED(NLEVEL_MIN)
               OSBF%NG = 0
               OSBF%NA = 0

               SELECT CASE (TYPE_MULTIGRID)

                  CASE (NSCARC_MULTIGRID_GEOMETRIC)

                     SBF%WALL(IWF)%IXN1 = M%WALL(IWF)%NOM_IB(1)
                     SBF%WALL(IWF)%IYN1 = M%WALL(IWF)%NOM_IB(2)
                     SBF%WALL(IWF)%IZN1 = M%WALL(IWF)%NOM_IB(3)
                     SBF%WALL(IWF)%IXN2 = M%WALL(IWF)%NOM_IB(4)
                     SBF%WALL(IWF)%IYN2 = M%WALL(IWF)%NOM_IB(5)
                     SBF%WALL(IWF)%IZN2 = M%WALL(IWF)%NOM_IB(6)

                  CASE (NSCARC_MULTIGRID_ALGEBRAIC)

                     NCPL = (M%WALL(IWF)%NOM_IB(4) - M%WALL(IWF)%NOM_IB(1) + 1) * &
                            (M%WALL(IWF)%NOM_IB(5) - M%WALL(IWF)%NOM_IB(2) + 1) * &
                            (M%WALL(IWF)%NOM_IB(6) - M%WALL(IWF)%NOM_IB(3) + 1) 

                     ALLOCATE(SBF%WALL(IWF)%ICN(NCPL), STAT=IERR)
                     CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICN',IERR)
      
                     ALLOCATE(SBF%WALL(IWF)%ICG(NCPL), STAT=IERR)
                     CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICG',IERR)
      
                     ICPL=0
                     DO IZ = M%WALL(IWF)%NOM_IB(3), M%WALL(IWF)%NOM_IB(6)
                        DO IY = M%WALL(IWF)%NOM_IB(2), M%WALL(IWF)%NOM_IB(5)
                           DO IX = M%WALL(IWF)%NOM_IB(1), M%WALL(IWF)%NOM_IB(4)
                              ICPL=ICPL+1
                              SBF%NCE = SBF%NCE + 1
                              OSBF%NG = OSBF%NG + 1
                              IC = (IZ-1)*MESHES(NOM)%IBAR*MESHES(NOM)%JBAR + (IY-1)*MESHES(NOM)%IBAR + IX
                              SBF%WALL(IWF)%ICN(ICPL)   = IC
                              SBF%WALL(IWF)%ICG(ICPL) = OSBF%NG
                           ENDDO
                        ENDDO
                     ENDDO

                     SBF%WALL(IWF)%NCPL = ICPL               

               END SELECT

            ENDIF


         ENDDO

         CALL SCARC_SETUP_SUBDIVISION(SBF%WALL, SBF%SUBDIVISION, SBF%NW)
         
         
         !!! Only in case of MG-method:
         BANDED_GMG_IF: IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_GEOMETRIC) THEN
         
            IREFINE=1
            BANDED_GMG_LEVEL_LOOP: DO NL = NLEVEL_MIN+1, NLEVEL_MAX
            
               !!! point to SCARC grid structures on coarser and finer level
               SBC => S%BANDED(NL)
               SBF => S%BANDED(NL-1)
         
               IREFINE=IREFINE*2

               SBC%NW = 2*SBC%NX*SBC%NY + 2*SBC%NX*SBC%NZ + 2*SBC%NY*SBC%NZ

               ALLOCATE(SBC%WALL(SBC%NW), STAT=IERR)
               CALL ChkMemErr('SCARC_SETUP_WALLINFO','WALL',IERR)
            
               !!! 
               !!! set wall cells for coarser grid and define corresponding WALL
               !!! 
               IWC=1
         
               !!! wall cells along IOR=1
               IOFFSET = 0
               DO IZC=1,SBC%NZ
                  DO IYC=1,SBC%NY
                     CALL SCARC_SETUP_BANDED_FACE(IWC,  1, IOFFSET, IREFINE, 0, IYC, IZC, SBF%NY, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=-1
              IOFFSET = SBF%NY*SBF%NZ
               DO IZC=1,SBC%NZ
                  DO IYC=1,SBC%NY
                     CALL SCARC_SETUP_BANDED_FACE(IWC, -1, IOFFSET, IREFINE, SBC%NX+1, IYC, IZC, SBF%NY, NM, NL)
                  ENDDO
               ENDDO
            
               !!! wall cells along IOR=2
               IOFFSET = 2*SBF%NY*SBF%NZ
               DO IZC=1,SBC%NZ
                  DO IXC=1,SBC%NX
                     CALL SCARC_SETUP_BANDED_FACE(IWC,  2, IOFFSET, IREFINE, IXC, 0, IZC, SBF%NX, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=-2
               IOFFSET = 2*SBF%NY*SBF%NZ + SBF%NX*SBF%NZ
               DO IZC=1,SBC%NZ
                  DO IXC=1,SBC%NX
                     CALL SCARC_SETUP_BANDED_FACE(IWC, -2, IOFFSET, IREFINE, IXC, SBC%NY+1, IZC, SBF%NX, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=3
               IOFFSET = 2*SBF%NY*SBF%NZ + 2*SBF%NX*SBF%NZ
               DO IYC=1,SBC%NY
                  DO IXC=1,SBC%NX
                     CALL SCARC_SETUP_BANDED_FACE(IWC,  3, IOFFSET, IREFINE, IXC, IYC, 0, SBF%NX, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=-3
               IOFFSET = 2*SBF%NY*SBF%NZ + 2*SBF%NX*SBF%NZ + SBF%NX*SBF%NY
               DO IYC=1,SBC%NY
                  DO IXC=1,SBC%NX
                     CALL SCARC_SETUP_BANDED_FACE(IWC, -3, IOFFSET, IREFINE, IXC, IYC, SBC%NZ+1, SBF%NX, NM, NL)
                  ENDDO
               ENDDO
         
               !!!
               !!! compute analogues to NIC, I_MIN, I_MAX, K_MIN, K_MAX on level 'NL'
               !!!
      
               !CALL SCARC_SETUP_COARSE_DIMENSIONS(IREFINE, NM, NL)
         
               !!! Store subdivision information on coarser level
               CALL SCARC_SETUP_SUBDIVISION(SBC%WALL, SBC%SUBDIVISION, SBC%NW)
         
            ENDDO BANDED_GMG_LEVEL_LOOP
         ENDIF BANDED_GMG_IF
      
      ENDDO MESHES_LOOP_BANDED

   !!!----------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      MESHES_LOOP_COMPACT: DO NM = NMESHES_MIN, NMESHES_MAX

         M => MESHES(NM)
         S => SCARC(NM)
            
         !!! For all solver: 
         !!! Determine array WALL and PRESSURE_BC_INDEX on finest level
         SCF => S%COMPACT(NLEVEL_MIN)
         
         SCF%NW   = M%N_EXTERNAL_WALL_CELLS
         SCF%NCE  = SCF%NC
         SCF%NLAYER = 1

         ALLOCATE(SCF%WALL(SCF%NW), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','WALL',IERR)

         ALLOCATE(SCF%INTERNAL_BDRY_CELL(SCF%NC), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','INTERNAL_BDRY_CELL',IERR)
         SCF%INTERNAL_BDRY_CELL=0

         DO IWF = 1, SCF%NW
      
            !!! -----------------------------------------------------------------------------
            !!! Determine boundary type for IWF
            !!! -----------------------------------------------------------------------------
            IF (M%WALL(IWF)%BOUNDARY_TYPE == OPEN_BOUNDARY) THEN
               SCF%WALL(IWF)%BTYPE = DIRICHLET
            ELSE IF (M%WALL(IWF)%NOM /= 0) THEN !****CHECK
               SCF%WALL(IWF)%BTYPE = INTERNAL
            !ELSE IF (M%BOUNDARY_TYPE(IWF) == NULL_BOUNDARY) THEN
            !   SCF%WALL(IWF)%BTYPE = DIRICHLET
            ELSE
               SCF%WALL(IWF)%BTYPE = NEUMANN
            ENDIF

            !!! -----------------------------------------------------------------------------
            !!! Determine wall and ghost cells and indices
            !!! -----------------------------------------------------------------------------
            SCF%WALL(IWF)%ICW = (M%WALL(IWF)%ONE_D%KKG-1)*M%IBAR*M%JBAR + &
                                (M%WALL(IWF)%ONE_D%JJG-1)*M%IBAR        + &
                                 M%WALL(IWF)%ONE_D%IIG

            SCF%WALL(IWF)%IXG =  M%WALL(IWF)%ONE_D%II
            SCF%WALL(IWF)%IYG =  M%WALL(IWF)%ONE_D%JJ
            SCF%WALL(IWF)%IZG =  M%WALL(IWF)%ONE_D%KK

            SCF%WALL(IWF)%IXW =  M%WALL(IWF)%ONE_D%IIG
            SCF%WALL(IWF)%IYW =  M%WALL(IWF)%ONE_D%JJG
            SCF%WALL(IWF)%IZW =  M%WALL(IWF)%ONE_D%KKG

            !!! -----------------------------------------------------------------------------
            !!! Determine neighbor and orientation
            !!! -----------------------------------------------------------------------------
            NOM = M%WALL(IWF)%NOM

            SCF%WALL(IWF)%NOM = NOM
            SCF%WALL(IWF)%IOR = M%WALL(IWF)%ONE_D%IOR

!WRITE(SCARC_LU,'(a,i3,a,i3,a,i3,a,i3)') 'SCARC(',NM,')%COMPACT(',NLEVEL_MIN,')%WALL(',IWF,')%NOM=',SCF%WALL(IWF)%NOM

            !!! -----------------------------------------------------------------------------
            !!! Determine neighboring cells and indices which must be exchanged
            !!! -----------------------------------------------------------------------------
            IF (NOM /= 0) THEN

               OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NLEVEL_MIN)

               SCF%INTERNAL_BDRY_CELL(SCF%WALL(IWF)%ICW) = NSCARC_LAYER_ONE

               NCPL = (M%WALL(IWF)%NOM_IB(4) - M%WALL(IWF)%NOM_IB(1) + 1) * &
                      (M%WALL(IWF)%NOM_IB(5) - M%WALL(IWF)%NOM_IB(2) + 1) * &
                      (M%WALL(IWF)%NOM_IB(6) - M%WALL(IWF)%NOM_IB(3) + 1) 

               !!! allocate wall information about neighbouring cells
               ALLOCATE(SCF%WALL(IWF)%ICN(NCPL), STAT=IERR)
               CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICN',IERR)

               !!! allocate wall information about ghost cells 
               ALLOCATE(SCF%WALL(IWF)%ICG(NCPL), STAT=IERR)
               CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICG',IERR)

               !!! allocate wall information about external cells 
               ALLOCATE(SCF%WALL(IWF)%ICE(NCPL), STAT=IERR)
               CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICE',IERR)

               ICPL=0
               DO IZ = M%WALL(IWF)%NOM_IB(3), M%WALL(IWF)%NOM_IB(6)
                  DO IY = M%WALL(IWF)%NOM_IB(2), M%WALL(IWF)%NOM_IB(5)
                     DO IX = M%WALL(IWF)%NOM_IB(1), M%WALL(IWF)%NOM_IB(4)
                        ICPL=ICPL+1
                        OSCF%NWS= OSCF%NWS + 1
                        SCF%NCE = SCF%NCE + 1
                        OSCF%NG = OSCF%NG + 1
                        IC = (IZ-1)*MESHES(NOM)%IBAR*MESHES(NOM)%JBAR + (IY-1)*MESHES(NOM)%IBAR + IX
                        SCF%WALL(IWF)%ICN(ICPL) = IC
                        SCF%WALL(IWF)%ICE(ICPL) = SCF%NCE
                        SCF%WALL(IWF)%ICG(ICPL) = OSCF%NG
                     ENDDO
                  ENDDO
               ENDDO

!WRITE(SCARC_LU,*) NM, ': 1  NOM:',NOM, ': OSCF%NWS=',OSCF%NWS, SCF%NW
               SCF%WALL(IWF)%NCPL = ICPL               

               SCF%WALL(IWF)%IXN1 = M%WALL(IWF)%NOM_IB(1)
               SCF%WALL(IWF)%IYN1 = M%WALL(IWF)%NOM_IB(2)
               SCF%WALL(IWF)%IZN1 = M%WALL(IWF)%NOM_IB(3)
               SCF%WALL(IWF)%IXN2 = M%WALL(IWF)%NOM_IB(4)
               SCF%WALL(IWF)%IYN2 = M%WALL(IWF)%NOM_IB(5)
               SCF%WALL(IWF)%IZN2 = M%WALL(IWF)%NOM_IB(6)

               IF (TYPE_LAYER == NSCARC_LAYER_TWO .AND. TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN

                  ALLOCATE(SCF%WALL(IWF)%ICN2(NCPL), STAT=IERR)
                  CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICN2',IERR)

                  ALLOCATE(SCF%WALL(IWF)%ICG2(NCPL), STAT=IERR)
                  CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICG2',IERR)

                  ALLOCATE(SCF%WALL(IWF)%ICE2(NCPL), STAT=IERR)
                  CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICE2',IERR)
!WRITE(SCARC_LU,*) NM, ': 11  NOM:',NOM, ': OSCF%NWS=',OSCF%NWS

                  IOFX= 0
                  IOFY= 0
                  IOFZ= 0
                  SELECT CASE(SCF%WALL(IWF)%IOR)
                     CASE ( 1)
                        IOFX=-1
                     CASE (-1)
                        IOFX= 1
                     CASE ( 2)
                        IOFY=-1
                     CASE (-2)
                        IOFY= 1
                     CASE ( 3)
                        IOFZ=-1
                     CASE (-3)
                        IOFZ= 1
                  END SELECT

!WRITE(SCARC_LU,*) NM, ': 12  NOM:',NOM, ': OSCF%NWS=',OSCF%NWS, SCF%NW
                  SCF%WALL(IWF)%ICW2  = (M%WALL(IWF)%ONE_D%KKG - IOFZ - 1)*M%IBAR*M%JBAR + &
                                        (M%WALL(IWF)%ONE_D%JJG - IOFY - 1)*M%IBAR        + &
                                         M%WALL(IWF)%ONE_D%IIG - IOFX

                  ICPL=0
                  DO IZ = M%WALL(IWF)%NOM_IB(3), M%WALL(IWF)%NOM_IB(6)
                     DO IY = M%WALL(IWF)%NOM_IB(2), M%WALL(IWF)%NOM_IB(5)
                        DO IX = M%WALL(IWF)%NOM_IB(1), M%WALL(IWF)%NOM_IB(4)
                           ICPL = ICPL + 1
                           OSCF%NWS= OSCF%NWS + 1
                           SCF%NCE = SCF%NCE + 1
                           OSCF%NG = OSCF%NG  + 1
                           IC = (IZ-1+IOFZ)*MESHES(NOM)%IBAR*MESHES(NOM)%JBAR + &
                                (IY-1+IOFY)*MESHES(NOM)%IBAR + IX+IOFX
                           SCF%WALL(IWF)%ICN2(ICPL) = IC
                           SCF%WALL(IWF)%ICE2(ICPL) = SCF%NCE
                           SCF%WALL(IWF)%ICG2(ICPL) = OSCF%NG 
                        ENDDO
                     ENDDO
                  ENDDO

               ENDIF
            ENDIF
         ENDDO

         ALLOCATE(SCF%WALL_PTR(SCF%NC+1:SCF%NCE), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','WALL_PTR',IERR)

         !ALLOCATE(SCF%GHOST_PTR(SCF%NC+1:SCF%NCE), STAT=IERR)
         !CALL ChkMemErr('SCARC_SETUP_WALLINFO','GHOST_PTR',IERR)

         COMPACT_WALL_PTR_LOOP: DO NOM = 1, NMESHES

            IF (NOM == NM) CYCLE COMPACT_WALL_PTR_LOOP

            OS => SCARC(NM)%OSCARC(NOM)
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0)  CYCLE COMPACT_WALL_PTR_LOOP

            OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NLEVEL_MIN)

            ALLOCATE(OSCF%GHOST_PTR(1:OSCF%NG), STAT=IERR)
            CALL ChkMemErr('SCARC_SETUP_WALLINFO','GHOST_PTR',IERR)

            ALLOCATE(OSCF%WALL_PTR(1:OSCF%NG), STAT=IERR)
            CALL ChkMemErr('SCARC_SETUP_WALLINFO','WALL_PTR',IERR)

            ALLOCATE(OSCF%NOM_PTR(1:OSCF%NC), STAT=IERR)
            CALL ChkMemErr('SCARC_SETUP_WALLINFO','NOM_PTR',IERR)

            OSCF%IG=0

         ENDDO COMPACT_WALL_PTR_LOOP

         DO IWF = 1, SCF%NW

            NOM = SCF%WALL(IWF)%NOM

            IF (NOM /= 0) THEN

               ICE = SCF%WALL(IWF)%ICE(1)
               SCF%WALL_PTR(ICE) = IWF

               OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NLEVEL_MIN)
               OSCF%IG = OSCF%IG + 1

               OSCF%GHOST_PTR(OSCF%IG)=SCF%WALL(IWF)%ICE(1)
               OSCF%WALL_PTR(OSCF%IG)=IWF

               IF (TYPE_LAYER == NSCARC_LAYER_TWO .AND. TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN
                  ICE2 = SCF%WALL(IWF)%ICE2(1)
                  SCF%WALL_PTR(ICE2) = - IWF
                  OSCF%GHOST_PTR(OSCF%IG) = SCF%WALL(IWF)%ICE2(1)
                  OSCF%WALL_PTR(OSCF%IG) = -IWF
               ENDIF

            ENDIF

         ENDDO
      
         CALL SCARC_SETUP_SUBDIVISION(SCF%WALL, SCF%SUBDIVISION, SCF%NW)

         !!! Only in case of MG-method:
         !!! Determine arrays WALL for coarser levels
         COMPACT_GMG_IF: IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_GEOMETRIC) THEN
         
            IREFINE=1
            COMPACT_GMG_LEVEL_LOOP: DO NL = NLEVEL_MIN+1, NLEVEL_MAX
            
               !!! point to SCARC grid structures on coarser and finer level
               SCC => S%COMPACT(NL)
               SCF => S%COMPACT(NL-1)
         
               IREFINE=IREFINE*2

               SCC%NW  = 2*SCC%NX*SCC%NY + 2*SCC%NX*SCC%NZ + 2*SCC%NY*SCC%NZ
               SCC%NC  = SCC%NX*SCC%NY*SCC%NZ
               SCC%NCE = SCC%NC

               ALLOCATE(SCC%WALL(SCC%NW), STAT=IERR)
               CALL ChkMemErr('SCARC_SETUP_WALLINFO','WALL',IERR)
      
               !!! 
               !!! set wall cells for coarser grid and define corresponding WALL
               !!! 
               IWC=1
               ICE=SCC%NC
         
!WRITE(SCARC_LU,*) 'CALLING COMPACT_FACE FOR LEVEL ', NL, ICE
               !!! wall cells along IOR=1
               IOFFSET = 0
               DO IZC=1,SCC%NZ
                  DO IYC=1,SCC%NY
                     CALL SCARC_SETUP_COMPACT_FACE(IWC,  1, IOFFSET, IREFINE, 0, IYC, IZC, SCF%NY, ICE, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=-1
              IOFFSET = SCF%NY*SCF%NZ
               DO IZC=1,SCC%NZ
                  DO IYC=1,SCC%NY
                     CALL SCARC_SETUP_COMPACT_FACE(IWC, -1, IOFFSET, IREFINE, SCC%NX+1, IYC, IZC, SCF%NY, ICE, NM, NL)
                  ENDDO
               ENDDO
            
               !!! wall cells along IOR=2
               IOFFSET = 2*SCF%NY*SCF%NZ
               DO IZC=1,SCC%NZ
                  DO IXC=1,SCC%NX
                     CALL SCARC_SETUP_COMPACT_FACE(IWC,  2, IOFFSET, IREFINE, IXC, 0, IZC, SCF%NX, ICE, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=-2
               IOFFSET = 2*SCF%NY*SCF%NZ + SCF%NX*SCF%NZ
               DO IZC=1,SCC%NZ
                  DO IXC=1,SCC%NX
                     CALL SCARC_SETUP_COMPACT_FACE(IWC, -2, IOFFSET, IREFINE, IXC, SCC%NY+1, IZC, SCF%NX, ICE, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=3
               IOFFSET = 2*SCF%NY*SCF%NZ + 2*SCF%NX*SCF%NZ
               DO IYC=1,SCC%NY
                  DO IXC=1,SCC%NX
                     CALL SCARC_SETUP_COMPACT_FACE(IWC,  3, IOFFSET, IREFINE, IXC, IYC, 0, SCF%NX, ICE, NM, NL)
                  ENDDO
               ENDDO
         
               !!! wall cells along IOR=-3
               IOFFSET = 2*SCF%NY*SCF%NZ + 2*SCF%NX*SCF%NZ + SCF%NX*SCF%NY
               DO IYC=1,SCC%NY
                  DO IXC=1,SCC%NX
                     CALL SCARC_SETUP_COMPACT_FACE(IWC, -3, IOFFSET, IREFINE, IXC, IYC, SCC%NZ+1, SCF%NX, ICE, NM, NL)
                  ENDDO
               ENDDO
               SCC%NCE = ICE
         
               !!!
               !!! compute analogues to NIC, I_MIN, I_MAX, K_MIN, K_MAX on level 'NL'
               !!!
      
               !CALL SCARC_SETUP_COARSE_DIMENSIONS(IREFINE, NM, NL)
         
               !!! Store subdivision information on coarser level
               CALL SCARC_SETUP_SUBDIVISION(SCC%WALL, SCC%SUBDIVISION, SCC%NW)
         
            ENDDO COMPACT_GMG_LEVEL_LOOP
         ENDIF COMPACT_GMG_IF
      
         
      ENDDO MESHES_LOOP_COMPACT

END SELECT SELECT_SYSTEM

!!!-------------------------------------------------------------------------------------------------------
!!! Initialize communication structures on finest level (if there is more than 1 mesh) 
!!!-------------------------------------------------------------------------------------------------------
IF (NMESHES>1) THEN

   NLMIN = NLEVEL_MIN
   NLMAX = NLEVEL_MIN
   IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_GEOMETRIC) NLMAX = NLEVEL_MAX

   CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_ALLOC_REAL, NLEVEL_MIN)
   DO NL = NLMIN, NLMAX
      CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_ALLOC_INT, NL)
      CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_WALL, NL)
   ENDDO

ENDIF

IF (TYPE_SYSTEM == NSCARC_SYSTEM_COMPACT .AND. TYPE_LATEX == NSCARC_LATEX_TABLE) THEN
   MLATEX = 98
   OPEN (MLATEX, FILE='tables/wall.tex')
   DO NM = NMESHES_MIN, NMESHES_MAX
      SCF => SCARC(NM)%COMPACT(NLEVEL_MIN)
      CALL SCARC_LATEX_WALL(MLATEX, NM, NLEVEL_MIN)
      LATEX_OMESH_LOOP: DO NOM = 1, NMESHES
         IF (NOM == NM) CYCLE LATEX_OMESH_LOOP
         OS => SCARC(NM)%OSCARC(NOM)
         IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0)  CYCLE LATEX_OMESH_LOOP
         OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NLEVEL_MIN)
         CALL SCARC_LATEX_NOM(MLATEX,NM, NOM, NLEVEL_MIN)
      ENDDO LATEX_OMESH_LOOP
   ENDDO
   CLOSE (MLATEX)
ENDIF

END SUBROUTINE SCARC_SETUP_WALLINFO


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Store subdivision information
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_SUBDIVISION(WALL, SUBDIVISION, NW)
TYPE (SCARC_WALL_TYPE), DIMENSION(:), INTENT(IN) :: WALL
INTEGER, DIMENSION(3,-3:3), INTENT(OUT) :: SUBDIVISION
INTEGER, INTENT(IN) :: NW
INTEGER :: IW, IOR0, IOR_LAST, NOM, INBR
INTEGER :: NEIGHBORS(20,-3:3)

IOR_LAST    = 0
NEIGHBORS   = 0
SUBDIVISION = 0
         
WALLCELL_LOOP: DO IW = 1, NW

   NOM  = WALL(IW)%NOM
   IOR0 = WALL(IW)%IOR
   
   IF (IOR_LAST /= IOR0) SUBDIVISION(1,IOR0) = IW
   SUBDIVISION(2,IOR0) = SUBDIVISION(2,IOR0) + 1
   
   IF (NOM /= 0) THEN
      NEIGHBOR_LOOP: DO INBR = 1, 20
         IF (NOM == NEIGHBORS(INBR, IOR0)) THEN
            EXIT NEIGHBOR_LOOP
         ELSE IF (NEIGHBORS(INBR, IOR0) /= 0) THEN
            CYCLE NEIGHBOR_LOOP
         ELSE IF (NEIGHBORS(INBR, IOR0) == 0) THEN
            NEIGHBORS(INBR, IOR0) = NOM
            SUBDIVISION(3,IOR0) = SUBDIVISION(3,IOR0) + 1
            EXIT NEIGHBOR_LOOP
         ELSE
            WRITE(*,*) 'More than 20 neighbors at one face not allowed yet!'
            STOP
         ENDIF
      ENDDO NEIGHBOR_LOOP
   ENDIF
   
   IOR_LAST = IOR0

ENDDO WALLCELL_LOOP
         
END SUBROUTINE SCARC_SETUP_SUBDIVISION


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set wall cell information on coarse level
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_BANDED_FACE(IWC, IOR0, IOFFSET, IREFINE, IX, IY, IZ, ILENF, NM, NL)
INTEGER, INTENT(INOUT) :: IWC
INTEGER, INTENT(IN) :: IOR0, IOFFSET, IREFINE, NM, NL
INTEGER, INTENT(IN) :: IX, IY, IZ, ILENF
INTEGER :: IWF(4) , IBCF(4), NOMF(4)
INTEGER :: I, IX1, IX2, IY1, IY2, IZ1, IZ2
INTEGER :: IDIFF, JDIFF, KDIFF
TYPE (SCARC_WALL_TYPE), DIMENSION(:), POINTER :: WALLC, WALLF

WALLC   => SCARC(NM)%BANDED(NL)%WALL                 ! WALL info of coarser level
WALLF   => SCARC(NM)%BANDED(NL-1)%WALL               ! WALL info of finer level

!!! Set orientation of neiboring face, indices of ghost and adjacent cell for coarse IW
!!!
WALLC(IWC)%IOR = IOR0

WALLC(IWC)%IXG = IX
WALLC(IWC)%IYG = IY
WALLC(IWC)%IZG = IZ

SELECT CASE (IOR0)
   CASE (1)
      WALLC(IWC)%IXW = IX+1
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ
   CASE (-1)
      WALLC(IWC)%IXW = IX-1
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ
   CASE (2)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY+1
      WALLC(IWC)%IZW = IZ
   CASE (-2)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY-1
      WALLC(IWC)%IZW = IZ
   CASE (3)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ+1
   CASE (-3)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ-1
END SELECT


SELECT CASE (TYPE_DIMENSION)

   !!!----------------------------------------------------------------------------------------------------
   !!! 2D-version
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DIMENSION_TWO)

      !!! determine fine IW's, which must be merged to one coarse IW
      SELECT CASE (ABS(IOR0))
         CASE ( 1)
            IWF(1) = IOFFSET +  2*IZ-1
         CASE ( 2)
            IWF(1) = IOFFSET + (2*IZ-1)*ILENF + 2*IX - 1
         CASE ( 3)
            IWF(1) = IOFFSET +  2*IX-1
      END SELECT
      IWF(2) = IWF(1)+1
   
      !!! set neighbors WALL(9,IWC) for coarser grid IWC
      NOMF(1) = WALLF(IWF(1))%NOM
      NOMF(2) = WALLF(IWF(2))%NOM
      IF (NOMF(1) /= NOMF(2)) THEN
         WRITE(*,*) 'SCARC_SETUP_BANDED_FACE: Inconsistent neighbors on IOR=', IOR0,' not allowed!'
         STOP
      ENDIF
   
      WALLC(IWC)%NOM = NOMF(1) 
   
      !!! set corresponding pressure_bc_index on coarser level
      IBCF(1) = WALLF(IWF(1))%BTYPE
      IBCF(2) = WALLF(IWF(2))%BTYPE
      IF (IBCF(1) == INTERNAL .OR. IBCF(2) == INTERNAL) THEN
         WALLC(IWC)%BTYPE = INTERNAL
      ELSE IF (IBCF(1) == DIRICHLET .OR. IBCF(2) == DIRICHLET) THEN
         WALLC(IWC)%BTYPE = DIRICHLET
      ELSE
         WALLC(IWC)%BTYPE = NEUMANN
      ENDIF
   
      !!! in case of an internal boundary set WALL(10:15,IWC)
      IF (NOMF(1) > 0) THEN   
   
         IY1 = 1
         IY2 = 1
         SELECT CASE (ABS(IOR0))
            CASE (1)
               KDIFF = WALLF(IWF(2))%IZN1 - WALLF(IWF(1))%IZN1
               IF (KDIFF == 1) THEN
                  IZ1 = WALLF(IWF(2))%IZN2/2
                  IZ2 = IZ1
               ELSE IF (KDIFF == 2) THEN
                  IZ1 = WALLF(IWF(1))%IZN2/2     
                  IZ2 = WALLF(IWF(2))%IZN2/2    
               ELSE IF (KDIFF == 0) THEN
                  IZ1 = (WALLF(IWF(1))%IZN2+1)/2
                  IZ2 = IZ1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_BANDED_FACE, IOR0=',IOR0
                  STOP
               ENDIF
            CASE (3)
               IDIFF = WALLF(IWF(2))%IXN1 - WALLF(IWF(1))%IXN1
               IF (IDIFF == 1) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
               ELSE IF (IDIFF == 2) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = WALLF(IWF(2))%IXN2/2
               ELSE IF (IDIFF == 0) THEN
                  IX1 = (WALLF(IWF(1))%IXN2+1)/2
                  IX2 = IX1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_BANDED_FACE, IOR0=',IOR0
                  STOP
               ENDIF
         END SELECT
   
         SELECT CASE (IOR0)
            CASE (1)
               IX1 = MESHES(NOMF(1))%IBAR/IREFINE
               IX2 = IX1
            CASE (-1)
               IX1 = 1
               IX2 = 1
            CASE (3)
               IZ1 = MESHES(NOMF(1))%KBAR/IREFINE
               IZ2 = IZ1
            CASE (-3)
               IZ1 = 1
               IZ2 = 1
         END SELECT
   
         !!!
         !!! Set ranges for data exchange
         !!!
         WALLC(IWC)%IXN1 = IX1
         WALLC(IWC)%IYN1 = IY1
         WALLC(IWC)%IZN1 = IZ1
         WALLC(IWC)%IXN2 = IX2
         WALLC(IWC)%IYN2 = IY2
         WALLC(IWC)%IZN2 = IZ2
   
      ENDIF
         

!!!----------------------------------------------------------------------------------------------------
!!! 3D-version
!!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DIMENSION_THREE)

      !!! determine fine IW's, which must be merged to one coarse IW
      SELECT CASE (ABS(IOR0))
         CASE (1)
            IWF(1) = IOFFSET + (2*IZ-2)*ILENF + 2*IY - 1
            IWF(3) = IOFFSET + (2*IZ-1)*ILENF + 2*IY - 1
         CASE (2)
            IWF(1) = IOFFSET + (2*IZ-2)*ILENF + 2*IX - 1
            IWF(3) = IOFFSET + (2*IZ-1)*ILENF + 2*IX - 1
         CASE (3)
            IWF(1) = IOFFSET + (2*IY-2)*ILENF + 2*IX - 1
            IWF(3) = IOFFSET + (2*IY-1)*ILENF + 2*IX - 1
      END SELECT
      IWF(2) = IWF(1)+1
      IWF(4) = IWF(3)+1
   
      !!! set neighbors WALL(9,IWC) for coarser grid IWC
      DO I=1,4
         NOMF(I) = WALLF(IWF(I))%NOM
      ENDDO
         
      IF (NOMF(1)/=NOMF(2) .OR. NOMF(1)/=NOMF(3) .OR. NOMF(1)/=NOMF(4)) THEN
         WRITE(*,*) 'SCARC_SETUP_BANDED_FACE: Inconsistent neighbors on IOR=', IOR0,' not allowed!'
         STOP
      ENDIF
      WALLC(IWC)%NOM = NOMF(1) 
   
      !!! set corresponding boundary type on coarser level
      DO I=1,4
         IBCF(I) = WALLF(IWF(I))%BTYPE
      ENDDO
      IF (IBCF(1)==INTERNAL.OR.IBCF(2)==INTERNAL.OR.&
          IBCF(3)==INTERNAL.OR.IBCF(4)==INTERNAL) THEN
         WALLC(IWC)%BTYPE =INTERNAL
      ELSE IF (IBCF(1)==DIRICHLET.OR.IBCF(2)==DIRICHLET.OR.&
               IBCF(3)==DIRICHLET.OR.IBCF(4)==DIRICHLET) THEN
         WALLC(IWC)%BTYPE =DIRICHLET
      ELSE
         WALLC(IWC)%BTYPE =NEUMANN
      ENDIF
   
      !!! in case of an internal boundary set WALL(10:15,IWC)
      IF (NOMF(1) > 0) THEN   
   
         SELECT CASE (ABS(IOR0))
            CASE (1)
               JDIFF = WALLF(IWF(2))%IYN1 - WALLF(IWF(1))%IYN1
               KDIFF = WALLF(IWF(3))%IZN1 - WALLF(IWF(1))%IZN1
               IF (JDIFF==1 .AND. KDIFF==1) THEN
                  IY1 = WALLF(IWF(2))%IYN2/2
                  IY2 = IY1
                  IZ1 = WALLF (IWF(3))%IZN2/2
                  IZ2 = IZ1
               ELSE IF (JDIFF==2 .AND. KDIFF==2) THEN
                  IY1 = WALLF (IWF(1))%IYN2/2
                  IY2 = WALLF (IWF(2))%IYN2/2
                  IZ1 = WALLF (IWF(1))%IZN2/2
                  IZ2 = WALLF (IWF(3))%IZN2/2
               ELSE IF (JDIFF==0 .AND. KDIFF==0) THEN
                  IY1 = WALLF (IWF(1))%IYN1/2
                  IY2 = IY1
                  IZ1 = WALLF (IWF(1))%IZN1/2
                  IZ2 = IZ1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_BANDED_FACE, IOR0=',IOR0
                  STOP
               ENDIF
            CASE (2)
               IDIFF = WALLF(IWF(2))%IXN1 - WALLF(IWF(1))%IXN1
               KDIFF = WALLF(IWF(3))%IZN1 - WALLF(IWF(1))%IZN1
               IF (IDIFF==1 .AND. KDIFF==1) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
                  IZ1 = WALLF(IWF(3))%IZN2/2
                  IZ2 = IZ1
               ELSE IF (IDIFF==2 .AND. KDIFF==2) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = WALLF(IWF(2))%IXN2/2
                  IZ1 = WALLF(IWF(1))%IZN2/2
                  IZ2 = WALLF(IWF(3))%IZN2/2
               ELSE IF (IDIFF==0 .AND. KDIFF==0) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = IX1
                  IZ1 = WALLF(IWF(1))%IZN2/2
                  IZ2 = IZ1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_BANDED_FACE, IOR0=',IOR0
                  STOP
               ENDIF
            CASE (3)
               IDIFF = WALLF(IWF(2))%IXN1 - WALLF(IWF(1))%IXN1
               JDIFF = WALLF(IWF(3))%IYN1 - WALLF(IWF(1))%IYN1
               IF (IDIFF==1 .AND. JDIFF==1) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
                  IY1 = WALLF(IWF(3))%IYN2/2
                  IY2 = IY1
               ELSE IF (IDIFF==2 .AND. JDIFF==2) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = WALLF(IWF(2))%IXN2/2
                  IY1 = WALLF(IWF(1))%IYN2/2
                  IY2 = WALLF(IWF(3))%IYN2/2
               ELSE IF (IDIFF==0 .AND. JDIFF==0) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
                  IY1 = WALLF(IWF(3))%IYN2/2
                  IY2 = IY1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_BANDED_FACE, IOR0=',IOR0
                  STOP
               ENDIF
         END SELECT
   
         SELECT CASE (IOR0)
            CASE (1)
               IX1 = MESHES(NOMF(1))%IBAR/IREFINE
               IX2 = IX1
            CASE (-1)
               IX1 = 1
               IX2 = IX1
            CASE (2)
               IY1 = MESHES(NOMF(1))%JBAR/IREFINE
               IY2 = IY1
            CASE (-2)
               IY1 = 1
               IY2 = IY1
            CASE (3)
               IZ1 = MESHES(NOMF(1))%KBAR/IREFINE
               IZ2 = IZ1
            CASE (-3)
               IZ1 = 1
               IZ2 = IZ1
         END SELECT
   
         !!!
         !!! Set WALLC(10:15, IWC)
         !!!
         WALLC(IWC)%IXN1 = IX1
         WALLC(IWC)%IYN1 = IY1
         WALLC(IWC)%IZN1 = IZ1
         WALLC(IWC)%IXN2 = IX2
         WALLC(IWC)%IYN2 = IY2
         WALLC(IWC)%IZN2 = IZ2
   
      ENDIF
   
END SELECT

IWC = IWC + 1

END SUBROUTINE SCARC_SETUP_BANDED_FACE



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set wall cell information on coarse level
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_COMPACT_FACE(IWC, IOR0, IOFFSET, IREFINE, IX, IY, IZ, ILENF, ICE, NM, NL)
INTEGER, INTENT(INOUT) :: IWC, ICE
INTEGER, INTENT(IN) :: IOR0, IOFFSET, IREFINE, NM, NL
INTEGER, INTENT(IN) :: IX, IY, IZ, ILENF
INTEGER :: IWF(4) , IBCF(4), NOMF(4)
INTEGER :: I, IX0, IY0, IZ0, IX1, IX2, IY1, IY2, IZ1, IZ2, IERR
INTEGER :: IDIFF, JDIFF, KDIFF, ICOUNT, ISUM
INTEGER, POINTER :: NXC, NYC, NZC, NXF, NYF, NZF
TYPE (SCARC_WALL_TYPE), DIMENSION(:), POINTER :: WALLC, WALLF
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSCC

WALLC => SCARC(NM)%COMPACT(NL)%WALL
WALLF => SCARC(NM)%COMPACT(NL-1)%WALL

NXF   => SCARC(NM)%COMPACT(NL-1)%NX
NYF   => SCARC(NM)%COMPACT(NL-1)%NY
NZF   => SCARC(NM)%COMPACT(NL-1)%NZ
NXC   => SCARC(NM)%COMPACT(NL)%NX
NYC   => SCARC(NM)%COMPACT(NL)%NY
NZC   => SCARC(NM)%COMPACT(NL)%NZ

!!! Set orientation of neiboring face, indices of ghost and adjacent cell for coarse IW
!!!
WALLC(IWC)%IOR = IOR0
!WALLC(IWC)%ICG(1) = (IZ-1)*NXC*NYC + (IY-1)*NXC + IX

SELECT CASE (IOR0)
   CASE (1)
      WALLC(IWC)%ICW = (IZ-1)*NXC*NYC + (IY-1)*NXC + IX + 1
   CASE (-1)
      WALLC(IWC)%ICW = (IZ-1)*NXC*NYC + (IY-1)*NXC + IX - 1
   CASE (2)
      WALLC(IWC)%ICW = (IZ-1)*NXC*NYC +  IY   *NXC + IX
   CASE (-2)
      WALLC(IWC)%ICW = (IZ-1)*NXC*NYC + (IY-2)*NXC + IX
   CASE (3)
      WALLC(IWC)%ICW =  IZ   *NXC*NYC + (IY-1)*NXC + IX
   CASE (-3)
      WALLC(IWC)%ICW = (IZ-2)*NXC*NYC + (IY-1)*NXC + IX
END SELECT


WALLC(IWC)%IOR = IOR0

WALLC(IWC)%IXG = IX
WALLC(IWC)%IYG = IY
WALLC(IWC)%IZG = IZ

!WALLC(IWC)%ICG(1) = 0

SELECT CASE (IOR0)
   CASE (1)
      WALLC(IWC)%IXW = IX+1
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ
   CASE (-1)
      WALLC(IWC)%IXW = IX-1
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ
   CASE (2)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY+1
      WALLC(IWC)%IZW = IZ
   CASE (-2)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY-1
      WALLC(IWC)%IZW = IZ
   CASE (3)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ+1
   CASE (-3)
      WALLC(IWC)%IXW = IX
      WALLC(IWC)%IYW = IY
      WALLC(IWC)%IZW = IZ-1
END SELECT


SELECT CASE (TYPE_DIMENSION)

   !!!----------------------------------------------------------------------------------------------------
   !!! 2D-version
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DIMENSION_TWO)

      !!! determine fine IW's, which must be merged to one coarse IW
      SELECT CASE (ABS(IOR0))
         CASE ( 1)
            IWF(1) = IOFFSET +  2*IZ-1
         CASE ( 2)
            IWF(1) = IOFFSET + (2*IZ-1)*ILENF + 2*IX - 1
         CASE ( 3)
            IWF(1) = IOFFSET +  2*IX-1
      END SELECT
      IWF(2) = IWF(1)+1
   
      !!! set fine cell neighbors (they must be the same for all fine IW's)
      NOMF(1) = WALLF(IWF(1))%NOM
      NOMF(2) = WALLF(IWF(2))%NOM
      IF (NOMF(1) /= NOMF(2)) THEN
         WRITE(*,*) 'SCARC_SETUP_COMPACT_FACE: Inconsistent neighbors on IOR=', IOR0,' not allowed!'
         STOP
      ENDIF
   
      WALLC(IWC)%NOM = NOMF(1) 
   
      !!! set corresponding pressure_bc_index on coarser level
      IBCF(1) = WALLF(IWF(1))%BTYPE
      IBCF(2) = WALLF(IWF(2))%BTYPE
      IF (IBCF(1) == INTERNAL .OR. IBCF(2) == INTERNAL) THEN
         WALLC(IWC)%BTYPE = INTERNAL
      ELSE IF (IBCF(1) == DIRICHLET .OR. IBCF(2) == DIRICHLET) THEN
         WALLC(IWC)%BTYPE = DIRICHLET
      ELSE
         WALLC(IWC)%BTYPE = NEUMANN
      ENDIF
   
!WRITE(SCARC_LU,*) 'TRUDI'

      !!! in case of an internal boundary set neighboring WALL cells
      IF (NOMF(1) > 0) THEN   
   
         OSCC => SCARC(NM)%OSCARC(NOMF(1))%COMPACT(NL)
         OSCC%NWS = OSCC%NWS + 1
!WRITE(SCARC_LU,*) 'OSCC(',NL,')%NWS=',OSCC%NWS
!WRITE(*,*) 'OSCC(',NL,')%NWS=',OSCC%NWS

         IY1 = 1
         IY2 = 1
         SELECT CASE (ABS(IOR0))
            CASE (1)
               KDIFF = WALLF(IWF(2))%IZN1 - WALLF(IWF(1))%IZN1
               IF (KDIFF == 1) THEN
                  IZ1 = WALLF(IWF(2))%IZN2/2
                  IZ2 = IZ1
               ELSE IF (KDIFF == 2) THEN
                  IZ1 = WALLF(IWF(1))%IZN2/2     
                  IZ2 = WALLF(IWF(2))%IZN2/2    
               ELSE IF (KDIFF == 0) THEN
                  IZ1 = (WALLF(IWF(1))%IZN2+1)/2
                  IZ2 = IZ1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_COMPACT_FACE, IOR0=',IOR0
                  STOP
               ENDIF
            CASE (3)
               IDIFF = WALLF(IWF(2))%IXN1 - WALLF(IWF(1))%IXN1
               IF (IDIFF == 1) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
               ELSE IF (IDIFF == 2) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = WALLF(IWF(2))%IXN2/2
               ELSE IF (IDIFF == 0) THEN
                  IX1 = (WALLF(IWF(1))%IXN2+1)/2
                  IX2 = IX1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_COMPACT_FACE, IOR0=',IOR0
                  STOP
               ENDIF
         END SELECT
   
         SELECT CASE (IOR0)
            CASE (1)
               IX1 = MESHES(NOMF(1))%IBAR/IREFINE
               IX2 = IX1
            CASE (-1)
               IX1 = 1
               IX2 = 1
            CASE (3)
               IZ1 = MESHES(NOMF(1))%KBAR/IREFINE
               IZ2 = IZ1
            CASE (-3)
               IZ1 = 1
               IZ2 = 1
         END SELECT
    
         WALLC(IWC)%IXN1 = IX1
         WALLC(IWC)%IYN1 = 1
         WALLC(IWC)%IZN1 = IZ1
         WALLC(IWC)%IXN2 = IX2
         WALLC(IWC)%IYN2 = 1
         WALLC(IWC)%IZN2 = IZ2

         !!!
         !!! Set ranges for data exchange
         !!!
         ISUM = (IZ2-IZ1+1)*(IX2-IX1+1)
         WALLC(IWC)%NCPL = ISUM

         ALLOCATE(WALLC(IWC)%ICN(ISUM), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_COMPACT_FACR','ICN',IERR)

         ALLOCATE(WALLC(IWC)%ICE(ISUM), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICE',IERR)

         ICOUNT = 1
         DO IZ0 = IZ1, IZ2
            DO IX0 = IX1, IX2
               ICE = ICE + 1
               WALLC(IWC)%ICN(ICOUNT) = (IZ0-1)*NXC + IX0
               WALLC(IWC)%ICE(ICOUNT) = ICE
               ICOUNT = ICOUNT + 1
            ENDDO
         ENDDO

   
      ENDIF
         

!!!----------------------------------------------------------------------------------------------------
!!! 3D-version
!!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DIMENSION_THREE)

      !!! determine fine IW's, which must be merged to one coarse IW
      SELECT CASE (ABS(IOR0))
         CASE (1)
            IWF(1) = IOFFSET + (2*IZ-2)*ILENF + 2*IY - 1
            IWF(3) = IOFFSET + (2*IZ-1)*ILENF + 2*IY - 1
         CASE (2)
            IWF(1) = IOFFSET + (2*IZ-2)*ILENF + 2*IX - 1
            IWF(3) = IOFFSET + (2*IZ-1)*ILENF + 2*IX - 1
         CASE (3)
            IWF(1) = IOFFSET + (2*IY-2)*ILENF + 2*IX - 1
            IWF(3) = IOFFSET + (2*IY-1)*ILENF + 2*IX - 1
      END SELECT
      IWF(2) = IWF(1)+1
      IWF(4) = IWF(3)+1
   
      !!! set fine cell neighbors (they must be the same for all fine IW's)
      DO I=1,4
         NOMF(I) = WALLF(IWF(I))%NOM
      ENDDO
         
      IF (NOMF(1)/=NOMF(2) .OR. NOMF(1)/=NOMF(3) .OR. NOMF(1)/=NOMF(4)) THEN
         WRITE(*,*) 'SCARC_SETUP_COMPACT_FACE: Inconsistent neighbors on IOR=', IOR0,' not allowed!'
         STOP
      ENDIF
      WALLC(IWC)%NOM = NOMF(1) 
   
      !!! set corresponding pressure_bc_index on coarser level
      DO I=1,4
         IBCF(I) = WALLF(IWF(I))%BTYPE
      ENDDO
      IF (IBCF(1)==INTERNAL.OR.IBCF(2)==INTERNAL.OR.&
          IBCF(3)==INTERNAL.OR.IBCF(4)==INTERNAL) THEN
         WALLC(IWC)%BTYPE =INTERNAL
      ELSE IF (IBCF(1)==DIRICHLET.OR.IBCF(2)==DIRICHLET.OR.&
               IBCF(3)==DIRICHLET.OR.IBCF(4)==DIRICHLET) THEN
         WALLC(IWC)%BTYPE =DIRICHLET
      ELSE
         WALLC(IWC)%BTYPE =NEUMANN
      ENDIF
   
      !!! in case of an internal boundary set WALL(10:15,IWC)
      IF (NOMF(1) > 0) THEN   
   
         SELECT CASE (ABS(IOR0))
            CASE (1)
               JDIFF = WALLF(IWF(2))%IYN1 - WALLF(IWF(1))%IYN1
               KDIFF = WALLF(IWF(3))%IZN1 - WALLF(IWF(1))%IZN1
               IF (JDIFF==1 .AND. KDIFF==1) THEN
                  IY1 = WALLF(IWF(2))%IYN2/2
                  IY2 = IY1
                  IZ1 = WALLF(IWF(3))%IZN2/2
                  IZ2 = IZ1
               ELSE IF (JDIFF==2 .AND. KDIFF==2) THEN
                  IY1 = WALLF(IWF(1))%IYN2/2
                  IY2 = WALLF(IWF(2))%IYN2/2
                  IZ1 = WALLF(IWF(1))%IZN2/2
                  IZ2 = WALLF(IWF(3))%IZN2/2
               ELSE IF (JDIFF==0 .AND. KDIFF==0) THEN
                  IY1 = WALLF(IWF(1))%IYN1/2
                  IY2 = IY1
                  IZ1 = WALLF(IWF(1))%IZN1/2
                  IZ2 = IZ1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_COMPACT_FACE, IOR0=',IOR0
                  STOP
               ENDIF
            CASE (2)
               IDIFF = WALLF(IWF(2))%IXN1 - WALLF(IWF(1))%IXN1
               KDIFF = WALLF(IWF(3))%IZN1 - WALLF(IWF(1))%IZN1
               IF (IDIFF==1 .AND. KDIFF==1) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
                  IZ1 = WALLF(IWF(3))%IZN2/2
                  IZ2 = IZ1
               ELSE IF (IDIFF==2 .AND. KDIFF==2) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = WALLF(IWF(2))%IXN2/2
                  IZ1 = WALLF(IWF(1))%IZN2/2
                  IZ2 = WALLF(IWF(3))%IZN2/2
               ELSE IF (IDIFF==0 .AND. KDIFF==0) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = IX1
                  IZ1 = WALLF(IWF(1))%IZN2/2
                  IZ2 = IZ1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_COMPACT_FACE, IOR0=',IOR0
                  STOP
               ENDIF
            CASE (3)
               IDIFF = WALLF(IWF(2))%IXN1 - WALLF(IWF(1))%IXN1
               JDIFF = WALLF(IWF(3))%IYN1 - WALLF(IWF(1))%IYN1
               IF (IDIFF==1 .AND. JDIFF==1) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
                  IY1 = WALLF(IWF(3))%IYN2/2
                  IY2 = IY1
               ELSE IF (IDIFF==2 .AND. JDIFF==2) THEN
                  IX1 = WALLF(IWF(1))%IXN2/2
                  IX2 = WALLF(IWF(2))%IXN2/2
                  IY1 = WALLF(IWF(1))%IYN2/2
                  IY2 = WALLF(IWF(3))%IYN2/2
               ELSE IF (IDIFF==0 .AND. JDIFF==0) THEN
                  IX1 = WALLF(IWF(2))%IXN2/2
                  IX2 = IX1
                  IY1 = WALLF(IWF(3))%IYN2/2
                  IY2 = IY1
               ELSE
                  WRITE(*,*) 'WRONG resolutions in SCARC_SETUP_COMPACT_FACE, IOR0=',IOR0
                  STOP
               ENDIF
         END SELECT
   
         SELECT CASE (IOR0)
            CASE (1)
               IX1 = MESHES(NOMF(1))%IBAR/IREFINE
               IX2 = IX1
            CASE (-1)
               IX1 = 1
               IX2 = IX1
            CASE (2)
               IY1 = MESHES(NOMF(1))%JBAR/IREFINE
               IY2 = IY1
            CASE (-2)
               IY1 = 1
               IY2 = IY1
            CASE (3)
               IZ1 = MESHES(NOMF(1))%KBAR/IREFINE
               IZ2 = IZ1
            CASE (-3)
               IZ1 = 1
               IZ2 = IZ1
         END SELECT
   
         WALLC(IWC)%IXN1 = IX1
         WALLC(IWC)%IYN1 = IY1
         WALLC(IWC)%IZN1 = IZ1
         WALLC(IWC)%IXN2 = IX2
         WALLC(IWC)%IYN2 = IY2
         WALLC(IWC)%IZN2 = IZ2

         !!!
         !!! Set WALLC(10:15, IWC)
         !!!
         ISUM = (IZ2-IZ1+1)*(IY2-IY1+1)*(IX2-IX1+1)
         WALLC(IWC)%NCPL = ISUM

         ALLOCATE(WALLC(IWC)%ICN(ISUM), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_COMPACT_FACR','ICN',IERR)

         ALLOCATE(WALLC(IWC)%ICE(ISUM), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','ICE',IERR)

         ICOUNT = 1
         DO IZ0 = IZ1, IZ2
            DO IY0 = IY1, IY2
               DO IX0 = IX1, IX2
                  ICE = ICE + 1
                  WALLC(IWC)%ICN(ICOUNT) = (IZ0-1)*NXC*NYC + (IY0-1)*NXC + IX0
                  WALLC(IWC)%ICE(ICOUNT) = ICE
                  ICOUNT = ICOUNT + 1
               ENDDO
            ENDDO
         ENDDO
   
      ENDIF
   
END SELECT

IWC = IWC + 1

END SUBROUTINE SCARC_SETUP_COMPACT_FACE


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set analogues to I_MIN, IMAX, J_MIN, J_MAX, K_MIN, K_MAX on coarse level (only GMG!)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_COARSE_DIMENSIONS(IREFINE, NM, NL)
INTEGER, INTENT(IN) :: IREFINE, NM, NL
INTEGER :: NOM, IMIN, IMAX, JMIN, JMAX, KMIN, KMAX, IERR, IW, NW
LOGICAL :: FOUND
TYPE (SCARC_TYPE) , POINTER :: S
TYPE (OSCARC_TYPE), POINTER :: OS
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

IERR = 0

S => SCARC(NM)

OTHER_MESH_LOOP: DO NOM = 1, NMESHES

   IF (NOM == NM) CYCLE OTHER_MESH_LOOP

   !!! let OS point to SCARC structure on neighboring mesh
   OS => S%OSCARC(NOM)
    
   IMIN=0
   IMAX=MESHES(NOM)%IBAR/IREFINE+1

   SELECT CASE (TYPE_DIMENSION)
      CASE (NSCARC_DIMENSION_TWO)
         JMIN=0
         JMAX=2
      CASE (NSCARC_DIMENSION_THREE)
         JMIN=0
         JMAX=MESHES(NOM)%JBAR/IREFINE+1
   END SELECT

   KMIN=0
   KMAX=MESHES(NOM)%KBAR/IREFINE+1
   
   OS%NIC_S = 0
   FOUND = .FALSE.

   SELECT CASE (TYPE_SYSTEM)
      CASE (NSCARC_SYSTEM_BANDED)
         SB => S%BANDED(NL)
         NW = SB%NW
         SEARCH_LOOP_BANDED: DO IW=1,NW
         
            ! neighborship structure already known from finest level
            IF (SB%WALL(IW)%NOM/=NOM) CYCLE SEARCH_LOOP_BANDED
            OS%NIC_S = OS%NIC_S + 1
            FOUND = .TRUE.
         
            SELECT CASE (SB%WALL(IW)%IOR)
               CASE ( 1)
                  IMIN=MAX(IMIN,SB%WALL(NM)%IXN1-1)
               CASE (-1) 
                  IMAX=MIN(IMAX,SB%WALL(NM)%IXN2+1)
               CASE ( 2) 
                  JMIN=MAX(JMIN,SB%WALL(NM)%IYN1-1)
               CASE (-2) 
                  JMAX=MIN(JMAX,SB%WALL(NM)%IYN2+1)
               CASE ( 3) 
                  KMIN=MAX(KMIN,SB%WALL(NM)%IZN1-1)
               CASE (-3)
                  KMAX=MIN(KMAX,SB%WALL(NM)%IZN2+1)
            END SELECT
         ENDDO SEARCH_LOOP_BANDED
      CASE (NSCARC_SYSTEM_COMPACT)
         SC => S%COMPACT(NL)
         NW = SC%NW
         SEARCH_LOOP_COMPACT: DO IW=1,NW
         
            ! neighborship structure already known from finest level
            IF (SC%WALL(IW)%NOM/=NOM) CYCLE SEARCH_LOOP_COMPACT
            OS%NIC_S = OS%NIC_S + 1
            FOUND = .TRUE.
         
            SELECT CASE (SC%WALL(IW)%IOR)
               CASE ( 1)
                  IMIN=MAX(IMIN,SC%WALL(NM)%IXN1-1)
               CASE (-1) 
                  IMAX=MIN(IMAX,SC%WALL(NM)%IXN2+1)
               CASE ( 2) 
                  JMIN=MAX(JMIN,SC%WALL(NM)%IYN1-1)
               CASE (-2) 
                  JMAX=MIN(JMAX,SC%WALL(NM)%IYN2+1)
               CASE ( 3) 
                  KMIN=MAX(KMIN,SC%WALL(NM)%IZN1-1)
               CASE (-3)
                  KMAX=MIN(KMAX,SC%WALL(NM)%IZN2+1)
            END SELECT
         ENDDO SEARCH_LOOP_COMPACT
   END SELECT

   
   IF (.NOT.FOUND) CYCLE OTHER_MESH_LOOP

   N_EXCHANGES = N_EXCHANGES+1

   OS%I_MIN_R = IMIN
   OS%I_MAX_R = IMAX
   OS%J_MIN_R = JMIN
   OS%J_MAX_R = JMAX
   OS%K_MIN_R = KMIN
   OS%K_MAX_R = KMAX
   
ENDDO OTHER_MESH_LOOP

END SUBROUTINE SCARC_SETUP_COARSE_DIMENSIONS

 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Allocate several global structures for data exchange 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_GLOBALS
INTEGER :: NM, NL, IERR
INTEGER :: IREFINE

IERR = 0

!!!-------------------------------------------------------------------------------------------------------
!!! Allocate arrays which are used for (global) communciations
!!!-------------------------------------------------------------------------------------------------------
ALLOCATE(NC_GLOBAL(NLEVEL_MIN:NLEVEL_MAX), STAT=IERR)
CALL CHKMEMERR ('SCARC_SETUP', 'NC_GLOBAL', IERR)
NC_GLOBAL = 0

ALLOCATE(NC_LOCAL(NMESHES), STAT=IERR)
CALL CHKMEMERR ('SCARC_SETUP', 'NC_LOCAL', IERR)
NC_LOCAL = 0

ALLOCATE(SP_LOCAL(NMESHES), STAT=IERR)
CALL CHKMEMERR ('SCARC_SETUP_GLOBAL', 'SP_LOCAL', IERR)
SP_LOCAL = 0.0_EB

!!!-------------------------------------------------------------------------------------------------------
!!! Compute global number of cells for all levels
!!!-------------------------------------------------------------------------------------------------------
IREFINE=0
LEVEL_LOOP: DO NL = NLEVEL_MIN, NLEVEL_MAX

   MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      SELECT CASE (TYPE_SYSTEM)
         CASE (NSCARC_SYSTEM_BANDED)
            NC_LOCAL(NM)=SCARC(NM)%BANDED(NL)%NC
         CASE (NSCARC_SYSTEM_COMPACT)
            NC_LOCAL(NM)=SCARC(NM)%COMPACT(NL)%NC
      END SELECT
   ENDDO MESHES_LOOP

   !!! Determine global number of cells for all levels 
   IF (NMESHES>1) THEN
      IF (USE_MPI) THEN
         CALL MPI_ALLREDUCE(NC_LOCAL(MYID+1),NC_GLOBAL(NL),1,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,IERR)
      ELSE
         NC_GLOBAL(NL)=0
         DO NM=1,NMESHES
            NC_GLOBAL(NL) = NC_GLOBAL(NL) + NC_LOCAL(NM)
         ENDDO
      ENDIF
   ELSE
      NC_GLOBAL(NL) = NC_LOCAL(1)
   ENDIF

ENDDO LEVEL_LOOP

END SUBROUTINE SCARC_SETUP_GLOBALS


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Allocate several global structures for data exchange 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_NEIGHBORS
INTEGER :: NM, NOM, NL, IERR
TYPE (OSCARC_TYPE), POINTER :: OS, OSO


IF (NMESHES < 0) THEN

   LEVEL_LOOP: DO NL = NLEVEL_MIN+1, NLEVEL_MAX
   
      MESHES_LOOP: DO NM=NMESHES_MIN,NMESHES_MAX
         OMESHES_LOOP: DO NOM=1,NMESHES
   
            OS  => SCARC(NM)%OSCARC(NOM)
            OSO => SCARC(NOM)%OSCARC(NM)
   
            IF (USE_MPI) THEN
               CALL MPI_SEND(OS%I_MIN_R,1,MPI_INTEGER,PROCESS(NOM),1,MPI_COMM_WORLD,IERR)
               CALL MPI_SEND(OS%I_MAX_R,1,MPI_INTEGER,PROCESS(NOM),1,MPI_COMM_WORLD,IERR)
               CALL MPI_SEND(OS%J_MIN_R,1,MPI_INTEGER,PROCESS(NOM),1,MPI_COMM_WORLD,IERR)
               CALL MPI_SEND(OS%J_MAX_R,1,MPI_INTEGER,PROCESS(NOM),1,MPI_COMM_WORLD,IERR)
               CALL MPI_SEND(OS%K_MIN_R,1,MPI_INTEGER,PROCESS(NOM),1,MPI_COMM_WORLD,IERR)
               CALL MPI_SEND(OS%K_MAX_R,1,MPI_INTEGER,PROCESS(NOM),1,MPI_COMM_WORLD,IERR)
               CALL MPI_SEND(OS%NIC_S,  1,MPI_INTEGER,PROCESS(NOM),1,MPI_COMM_WORLD,IERR)
            ELSE
               OSO%I_MIN_S = OS%I_MIN_R
               OSO%I_MAX_S = OS%I_MAX_R
               OSO%J_MIN_S = OS%J_MIN_R
               OSO%J_MAX_S = OS%J_MAX_R
               OSO%K_MIN_S = OS%K_MIN_R
               OSO%K_MAX_S = OS%K_MAX_R
               OSO%NIC_R   = OS%NIC_S
            ENDIF

         ENDDO OMESHES_LOOP
      ENDDO MESHES_LOOP
   
      MESHES_LOOP2: DO NM=1,NMESHES
         OMESHES_LOOP2: DO NOM=NMESHES_MIN,NMESHES_MAX
   
            OSO => SCARC(NOM)%OSCARC(NM)
   
            IF (USE_MPI) THEN
               CALL MPI_RECV(OSO%I_MIN_S,1,MPI_INTEGER,PROCESS(NM),1,MPI_COMM_WORLD,STATUS2_SCARC,IERR)
               CALL MPI_RECV(OSO%I_MAX_S,1,MPI_INTEGER,PROCESS(NM),1,MPI_COMM_WORLD,STATUS2_SCARC,IERR)
               CALL MPI_RECV(OSO%J_MIN_S,1,MPI_INTEGER,PROCESS(NM),1,MPI_COMM_WORLD,STATUS2_SCARC,IERR)
               CALL MPI_RECV(OSO%J_MAX_S,1,MPI_INTEGER,PROCESS(NM),1,MPI_COMM_WORLD,STATUS2_SCARC,IERR)
               CALL MPI_RECV(OSO%K_MIN_S,1,MPI_INTEGER,PROCESS(NM),1,MPI_COMM_WORLD,STATUS2_SCARC,IERR)
               CALL MPI_RECV(OSO%K_MAX_S,1,MPI_INTEGER,PROCESS(NM),1,MPI_COMM_WORLD,STATUS2_SCARC,IERR)
               CALL MPI_RECV(OSO%NIC_R,  1,MPI_INTEGER,PROCESS(NM),1,MPI_COMM_WORLD,STATUS2_SCARC,IERR)
            ENDIF
   
         ENDDO OMESHES_LOOP2
      ENDDO MESHES_LOOP2
   
   ENDDO LEVEL_LOOP

ENDIF

END SUBROUTINE SCARC_SETUP_NEIGHBORS

 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Setup system of equation:
!!! Define matrix stencils and initialize matrices and boundary conditions on all needed levels
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_SYSTEM
INTEGER :: NM, NL, IERR
TYPE (SCARC_TYPE), POINTER :: S

IERR = 0
 
SELECT CASE (TYPE_SYSTEM)

   CASE (NSCARC_SYSTEM_BANDED)

      SELECT CASE (TYPE_MULTIGRID)
         CASE (NSCARC_MULTIGRID_GEOMETRIC)
            DO NL=NLEVEL_MIN, NLEVEL_MAX
               CALL SCARC_SETUP_SIZES (NSCARC_SIZE_MATRIXB , NL)
            ENDDO
         CASE DEFAULT
            CALL SCARC_SETUP_SIZES (NSCARC_SIZE_MATRIXB , NLEVEL_MIN)
      END SELECT

   CASE (NSCARC_SYSTEM_COMPACT)

      SELECT CASE (TYPE_MULTIGRID)
         CASE (NSCARC_MULTIGRID_GEOMETRIC)
            DO NL=NLEVEL_MIN, NLEVEL_MAX
               CALL SCARC_SETUP_SIZES (NSCARC_SIZE_MATRIXC , NL)
            ENDDO
         CASE DEFAULT
            CALL SCARC_SETUP_SIZES (NSCARC_SIZE_MATRIXC , NLEVEL_MIN)
      END SELECT

END SELECT

MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

   S  => SCARC(NM)

   SELECT_SOLVER: SELECT CASE (TYPE_METHOD)
   
      !!!-------------------------------------------------------------------------------------------------
      !!! Krylov method (CG/BICG) as main solver, different preconditioners possible
      !!!-------------------------------------------------------------------------------------------------
      CASE (NSCARC_METHOD_KRYLOV)
   
         SELECT_PRECON: SELECT CASE (TYPE_PRECON)
   
            !!!-------------------------------------------------------------------------------------------
            !!! in case of multigrid as preconditioner:
            !!!-------------------------------------------------------------------------------------------
            CASE (NSCARC_PRECON_MULTIGRID)
   
               SELECT_PRECON_MG: SELECT CASE (TYPE_MULTIGRID)
   
                  !!! geometric multigrid:
                  !!!    -  use banded storage technique on all levels unless otherwise specified
                  !!!    -  assemble standard n-point-matrix hierarchy on all levels (finest and all coarser)
                  CASE (NSCARC_MULTIGRID_GEOMETRIC)
                     
                     DO NL = NLEVEL_MIN, NLEVEL_MAX
                        CALL SCARC_SETUP_MATRIX  (NM, NL)
                        CALL SCARC_SETUP_BOUNDARY(NM, NL)
                     ENDDO 
   
                  !!! algebraic multigrid:
                  !!!    -  use compact storage technique on all levels (no other choise possible!)
                  !!!    -  assemble standard n-point-matrix only on finest level 
                  !!!    -  construct all coarser levels by requested coarsening strategy
                  CASE (NSCARC_MULTIGRID_ALGEBRAIC)
   
                     CALL SCARC_SETUP_MATRIX  (NM, NLEVEL_MIN)
                     CALL SCARC_SETUP_BOUNDARY(NM, NLEVEL_MIN)
   
               END SELECT SELECT_PRECON_MG
   
            !!!-------------------------------------------------------------------------------------------
            !!! in case of one-level preconditioners (JACOBI/SSOR/GSTRIX/FFT)
            !!!    -  use banded storage technique on finest level unless otherwise specified 
            !!!    -  assemble standard n-point-matrix on finest level 
            !!!-------------------------------------------------------------------------------------------
            CASE DEFAULT
   
               CALL SCARC_SETUP_MATRIX  (NM, NLEVEL_MIN)
               CALL SCARC_SETUP_BOUNDARY(NM, NLEVEL_MIN)
   
         END SELECT SELECT_PRECON
   
      !!!-------------------------------------------------------------------------------------------------
      !!! Multigrid as main solver
      !!!-------------------------------------------------------------------------------------------------
      CASE (NSCARC_METHOD_MULTIGRID)
   
         SELECT_MG: SELECT CASE (TYPE_MULTIGRID)
   
            !!!-------------------------------------------------------------------------------------------
            !!! geometric multigrid:
            !!!    -  use banded storage technique on all levels unless otherwise specified 
            !!!    -  assemble standard n-point-matrix hierarchy on all levels 
            !!!-------------------------------------------------------------------------------------------
            CASE (NSCARC_MULTIGRID_GEOMETRIC)
   
               DO NL = NLEVEL_MIN, NLEVEL_MAX
                  CALL SCARC_SETUP_MATRIX(NM, NL)
                  CALL SCARC_SETUP_BOUNDARY(NM, NL)
               ENDDO 

   
            !!!-------------------------------------------------------------------------------------------
            !!! algebraic multigrid:
            !!!    -  use compact storage technique (no other choice possible!)
            !!!    -  assemble standard n-point-matrix only on finest level
            !!!    -  construct all coarser levels later by requested coarsening strategy
            !!!-------------------------------------------------------------------------------------------
            CASE (NSCARC_MULTIGRID_ALGEBRAIC)
   
               CALL SCARC_SETUP_MATRIX(NM, NLEVEL_MIN)
               CALL SCARC_SETUP_BOUNDARY(NM, NLEVEL_MIN)

         END SELECT SELECT_MG
   
   END SELECT SELECT_SOLVER
   
ENDDO MESHES_LOOP

DO NL=NLEVEL_MIN, NLEVEL_MIN
   CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIX , NL, 'SETUP_SYSTEM0', 'MATRIX')
   !CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_WALLINFO , NL, 'SETUP_SYSTEM0', 'WALL')
ENDDO

!!!-------------------------------------------------------------------------------------------------------
!!! Exchange matrix entries along internal boundaries:
!!!  - in case of GMG as solver or preconditioner: matrices of all levels must be exchanged
!!!  - in all other cases: only matrix of finest level must be exchanged
!!!-------------------------------------------------------------------------------------------------------
IF (NMESHES>1) THEN

   SELECT CASE (TYPE_MULTIGRID)

      CASE (NSCARC_MULTIGRID_GEOMETRIC)

         !!! get subdiagonal entries along internal boundaries
         TYPE_MATRIX = NSCARC_MATRIX_SUBDIAG
         DO NL = NLEVEL_MIN, NLEVEL_MAX
            CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MATRIX, NL)
         ENDDO

      CASE DEFAULT

         !!! get subdiagonal entries along internal boundaries
         TYPE_MATRIX = NSCARC_MATRIX_SUBDIAG
         CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MATRIX, NLEVEL_MIN)

         IF (TYPE_SYSTEM == NSCARC_SYSTEM_COMPACT) THEN

            !!! set sizes for matrix stencils on overlapping parts
            TYPE_MATRIX = NSCARC_MATRIX_STENCIL
            CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MATRIX, NLEVEL_MIN)
            CALL SCARC_SETUP_OVERLAPS (NSCARC_MATRIX_STENCIL, NLEVEL_MIN)

            !!! exchange matrix entries on overlapping parts
            TYPE_MATRIX = NSCARC_MATRIX_SYSTEM
            CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MATRIX, NLEVEL_MIN)
            CALL SCARC_SETUP_OVERLAPS (NSCARC_MATRIX_SYSTEM, NLEVEL_MIN)

         ENDIF
   END SELECT

ENDIF

DO NL=NLEVEL_MIN, NLEVEL_MIN
   CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIX , NL, 'SETUP_SYSTEM', 'MATRIX')
   CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_WALLINFO , NL, 'SETUP_SYSTEM', 'WALLINFO')
ENDDO


!!!-------------------------------------------------------------------------------------------------------
!!! If multigrid is used, setup global coarse grid matrix in case of a direct coarse grid solver
!!!-------------------------------------------------------------------------------------------------------
IF ((TYPE_METHOD == NSCARC_METHOD_MULTIGRID .OR. TYPE_PRECON == NSCARC_PRECON_MULTIGRID) .AND. &
     TYPE_COARSE == NSCARC_COARSE_DIRECT) THEN
   WRITE(*,*) 'ACHTUNG: SETUP_COARSE_MATRIX muss noch an die neue WALL-Struktur angepasst werden!'
   STOP
   !CALL SCARC_SETUP_COARSE_MATRIX(NLEVEL_MAX)
ENDIF


SELECT CASE (TYPE_MULTIGRID)
   CASE (NSCARC_MULTIGRID_GEOMETRIC)
      DO NL=NLEVEL_MIN, NLEVEL_MAX
         CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIX , NL, 'SETUP_SYSTEM', 'MATRIX000')
         CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_WALLINFO , NL, 'SETUP_SYSTEM', 'WALLINFO')
      ENDDO
   CASE (NSCARC_MULTIGRID_ALGEBRAIC)
      CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIX , NLEVEL_MIN, 'SETUP_SYSTEM', 'MATRIX000')
      CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_WALLINFO , NLEVEL_MIN, 'SETUP_SYSTEM', 'WALLINFO')
END SELECT

!CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIXE, NLEVEL_MIN, 'SETUP_SYSTEM', 'MATRIXE')
CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_BCINDEX, NLEVEL_MIN, 'SETUP_SYSTEM', 'PRESSURE_BC_INDEX')
CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_ACELL  , NLEVEL_MIN, 'SETUP_SYSTEM', 'WALL_CELL')
CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_GCELL  , NLEVEL_MIN, 'SETUP_SYSTEM', 'GHOST_CELL')
CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_NCELL  , NLEVEL_MIN, 'SETUP_SYSTEM', 'NOM_CELL')
END SUBROUTINE SCARC_SETUP_SYSTEM



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Allocate matrix for the usual 5-point-stencil (2D) or 7-point-stencil (3D)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_MATRIX (NM, NL)
INTEGER, INTENT(IN) :: NM, NL
INTEGER :: I, J, K, IC, IP, IW=0, IW0(-3:3), IL0(-3:3), IERR, NA, NC
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC
TYPE (MESH_TYPE), POINTER :: M

M  => MESHES(NM)


SELECT CASE (TYPE_SYSTEM)

!!!----------------------------------------------------------------------------------------------------
!!! Bandwise storage technique:
!!!
!!! The matrix is stored "banded", namely diagonal for diagonal.
!!! Although the sub- and superdiagonals are shorter than the main diagonal,
!!! all bands are stored in the same length and are simply filled with zeros
!!! at redundant positions. The 'wasting' of this storage space is justified
!!! by the possibility to use a much more efficient matrix-vector-multiplication
!!! (which must not use an expensive referencing logic)
!!!
!!! A(.,ILZ)  : lower subdiagonal corresponding to z-coordinate
!!! A(.,ILY)  : lower subdiagonal corresponding to y-coordinate  (only 3D)
!!! A(.,ILX)  : lower subdiagonal corresponding to x-coordinate
!!! A(.,ID )  : main diagonal
!!! A(.,IUX)  : upper subdiagonal corresponding to x-coordinate
!!! A(.,IUY)  : upper subdiagonal corresponding to y-coordinate  (only 3D)
!!! A(.,IUZ)  : upper subdiagonal corresponding to z-coordinate
!!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      SB => SCARC(NM)%BANDED(NL)

      SELECT CASE (TYPE_DIMENSION)

         !!! --------------------- 2D ---------------------
         CASE (NSCARC_DIMENSION_TWO)
      
            ALLOCATE (SB%A(SB%NC, SB%NCPL), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_MATRIX', 'SB%A', IERR)
            SB%A = 0.0_EB
      
            ID  = 1                                                  ! pointer to the single subdiagonals
            ILZ = 2
            ILX = 3
            IUX = 4
            IUZ = 5
         
            J = 1
            DO K = 1, SB%NZ
               DO I = 1, SB%NX
              
                  IC = (K-1) * SB%NX + I
              
                  !!! main diagonal
                  SB%A(IC,ID) = - 2.0_EB*SB%DXI2 - 2.0_EB*SB%DZI2   
                
                  ! lower subdiagonal in z-direction
                  IF (K > 1) THEN
                     SB%A(IC,ILZ) = SB%DZI2                       
                  ELSE IF (SB%SUBDIVISION(3,3) > 0) THEN
                     IW0(3) = SB%SUBDIVISION(1,3)
                     IL0(3) = SB%SUBDIVISION(2,3)
                     IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(3),IL0(3))) SB%A(IC,ILZ) = -IW
                  ENDIF

                  !!! lower subdiagonal in x-direction
                  IF (I > 1) THEN
                     SB%A(IC,ILX) = SB%DXI2                      
                  ELSE IF (SB%SUBDIVISION(3,1) > 0) THEN
                     IW0(1) = SB%SUBDIVISION(1,1)
                     IL0(1) = SB%SUBDIVISION(2,1)
                     IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(1),IL0(1))) SB%A(IC,ILX) = -IW
                  ENDIF

                  ! upper subdiagonal in x-direction
                  IF (I < SB%NX) THEN
                     SB%A(IC,IUX) = SB%DXI2                     
                  ELSE IF (SB%SUBDIVISION(3,-1) > 0) THEN
                     IW0(-1) = SB%SUBDIVISION(1,-1)
                     IL0(-1) = SB%SUBDIVISION(2,-1)
                     IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(-1),IL0(-1))) SB%A(IC,IUX) = -IW
                  ENDIF

                  ! upper subdiagonal in z-direction
                  IF (K < SB%NZ) THEN
                     SB%A(IC,IUZ) = SB%DZI2                    
                  ELSE  IF (SB%SUBDIVISION(3,-3) > 0) THEN
                     IW0(-3) = SB%SUBDIVISION(1,-3)
                     IL0(-3) = SB%SUBDIVISION(2,-3)
                     IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(-3),IL0(-3))) SB%A(IC,IUZ) = -IW
                  ENDIF
              
               ENDDO
            ENDDO
      
         !!! --------------------- 3D ---------------------
         CASE (NSCARC_DIMENSION_THREE)
    
            ALLOCATE (SB%A(SB%NC, SB%NCPL), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_MATRIX', 'SB%A', IERR)
            SB%A = 0.0_EB
      
            ID  = 1                                                  ! pointer to the single subdiagonals
            ILZ = 2
            ILY = 3
            ILX = 4
            IUX = 5
            IUY = 6
            IUZ = 7

            DO K = 1, SB%NZ
               DO J = 1, SB%NY
                  DO I = 1, SB%NX
             
                     IC = (K-1) * SB%NX * SB%NY + (J-1) * SB%NX + I
             
                     !!! main diagonal
                     SB%A(IC,ID) = - 2.0_EB*SB%DXI2 - 2.0_EB*SB%DYI2 - 2.0_EB*SB%DZI2   
             
                     ! lower subdiagonal in z-direction
                     IF (K > 1) THEN
                        SB%A(IC,ILZ) = SB%DZI2                       
                     ELSE IF (SB%SUBDIVISION(3,3) > 0) THEN
                        IW0(3) = SB%SUBDIVISION(1,3)
                        IL0(3) = SB%SUBDIVISION(2,3)
                        IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(3),IL0(3))) SB%A(IC,ILZ) = -IW
                     ENDIF
   
                     ! lower subdiagonal in y-direction
                     IF (J > 1) THEN
                        SB%A(IC,ILY) = SB%DYI2                       
                     ELSE IF (SB%SUBDIVISION(3,2) > 0) THEN
                        IW0(2) = SB%SUBDIVISION(1,2)
                        IL0(2) = SB%SUBDIVISION(2,2)
                        IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(2),IL0(2))) SB%A(IC,ILY) = -IW
                     ENDIF
   
                     !!! lower subdiagonal in x-direction
                     IF (I > 1) THEN
                        SB%A(IC,ILX) = SB%DXI2                      
                     ELSE IF (SB%SUBDIVISION(3,1) > 0) THEN
                        IW0(1) = SB%SUBDIVISION(1,1)
                        IL0(1) = SB%SUBDIVISION(2,1)
                        IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(1),IL0(1))) SB%A(IC,ILX) = -IW
                     ENDIF

                     ! upper subdiagonal in x-direction
                     IF (I < SB%NX) THEN
                        SB%A(IC,IUX) = SB%DXI2                     
                     ELSE IF (SB%SUBDIVISION(3,-1) > 0) THEN
                        IW0(-1) = SB%SUBDIVISION(1,-1)
                        IL0(-1) = SB%SUBDIVISION(2,-1)
                        IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(-1),IL0(-1))) SB%A(IC,IUX) = -IW
                     ENDIF
   
                     ! upper subdiagonal in y-direction
                     IF (J < SB%NY) THEN
                        SB%A(IC,IUY) = SB%DYI2                     
                     ELSE IF (SB%SUBDIVISION(3,-2) > 0) THEN
                        IW0(-2) = SB%SUBDIVISION(1,-2)
                        IL0(-2) = SB%SUBDIVISION(2,-2)
                        IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(-2),IL0(-2))) SB%A(IC,IUY) = -IW
                     ENDIF
   
                     ! upper subdiagonal in z-direction
                     IF (K < SB%NZ) THEN
                        SB%A(IC,IUZ) = SB%DZI2                    
                     ELSE IF (SB%SUBDIVISION(3,-3) > 0) THEN
                        IW0(-3) = SB%SUBDIVISION(1,-3)
                        IL0(-3) = SB%SUBDIVISION(2,-3)
                        IF (BANDED_CELL_WITH_NEIGHBOR(SB%WALL, I,J,K,IW,IW0(-3),IL0(-3))) SB%A(IC,IUZ) = -IW
                     ENDIF
             
                  ENDDO
               ENDDO
            ENDDO
             
      END SELECT
             

!!!----------------------------------------------------------------------------------------------------
!!! Compact storage technique:
!!!
!!! Compression technique to store sparse matrices, non-zero entries are stored
!!! in a 1D-vector B(.), row after row, 
!!! each row starts with its diagonal entry followed by the other non-zero entries
!!! In order to identify each element, pointer arrays ROW and COL are needed,
!!! ROW points to the several diagonal entries in vector B(.), 
!!! COL points to the columns which non-zero entries in the matrix stencil
!!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      SC => SCARC(NM)%COMPACT(NL)

!! ONLY TEMPORARILY !!!
!SC%DXI2=1.0_EB
!SC%DYI2=1.0_EB
!SC%DZI2=1.0_EB

      IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN
         NA = SC%NAE
         NC = SC%NCE
      ELSE
         NA = SC%NAE
         NC = SC%NCE
      ENDIF

      ALLOCATE (SC%A_ROW(NC+10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_MATRIX', 'SC%A_ROW', IERR)
      SC%A_ROW = 0
      
      SELECT CASE (TYPE_DIMENSION)
      
         !!! --------------------- 2D ---------------------
         CASE (NSCARC_DIMENSION_TWO)

            ALLOCATE (SC%A(NA+10), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_MATRIX', 'SC%A', IERR)
            SC%A = 0.0_EB
            
            ALLOCATE (SC%A_COL(NA+10), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_MATRIX', 'SC%A_COL', IERR)
            SC%A_COL = 0.0_EB
      
            J   = 1
            IP  = 1
            IW0 = 0
            DO K = 1, SC%NZ
               DO I = 1, SC%NX
  
                  IC = (K-1) * SC%NX + I

                  !!! main diagonal
                  SC%A(IP)     = - 2.0_EB*SC%DXI2 - 2.0_EB*SC%DZI2      
                  SC%A_ROW(IC) = IP                                     
                  SC%A_COL(IP) = IC                                     
                  IP = IP + 1
         
                  ! lower subdiagonal in z-direction
                  IF (K > 1) THEN
                     SC%A(IP)    = SC%DZI2           
                     SC%A_COL(IP) = IC - SC%NX
                     IP = IP + 1
                  ELSE IF (SC%SUBDIVISION(3,3) > 0) THEN      !!! neighbor in lower k direction ?
                     IW0(3) = SC%SUBDIVISION(1,3)
                     IL0(3) = SC%SUBDIVISION(2,3)
                     IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(3),IL0(3))) THEN
                        SC%A_COL(IP) = -IW
                        IP = IP + 1
                     ENDIF
                  ENDIF
   
                  !!! lower subdiagonal in x-direction
                  IF (I > 1) THEN
                     SC%A(IP)    = SC%DXI2                            
                     SC%A_COL(IP) = IC - 1
                     IP = IP + 1
                  ELSE IF (SC%SUBDIVISION(3,1) > 0) THEN      !!! neighbor in lower x direction ?
                     IW0(1) = SC%SUBDIVISION(1,1)
                     IL0(1) = SC%SUBDIVISION(2,1)
                     IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(1),IL0(1))) THEN
                        SC%A_COL(IP) = -IW
                        IP = IP + 1
                     ENDIF
                  ENDIF
   
                  ! upper subdiagonal in x-direction
                  IF (I < SC%NX) THEN
                     SC%A(IP)    = SC%DXI2           
                     SC%A_COL(IP) = IC + 1
                     IP = IP + 1
                  ELSE IF (SC%SUBDIVISION(3,-1) > 0) THEN      !!! neighbor in upper x direction ?
                     IW0(-1) = SC%SUBDIVISION(1,-1)
                     IL0(-1) = SC%SUBDIVISION(2,-1)
                     IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(-1),IL0(-1))) THEN
                        SC%A_COL(IP) = -IW
                        IP = IP + 1
                     ENDIF
                  ENDIF
   
                  ! upper subdiagonal in z-direction      
                  IF (K < SC%NZ) THEN
                     SC%A(IP)    = SC%DZI2           
                     SC%A_COL(IP) = IC + SC%NX
                     IP = IP + 1
                  ELSE IF (SC%SUBDIVISION(3,-3) > 0) THEN      !!! neighbor in upper k direction ?
                     IW0(-3) = SC%SUBDIVISION(1,-3)
                     IL0(-3) = SC%SUBDIVISION(2,-3)
                     IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(-3),IL0(-3))) THEN
                        SC%A_COL(IP) = -IW
                        IP = IP + 1
                     ENDIF
                  ENDIF
   
               ENDDO
            ENDDO
         
         !!! --------------------- 3D ---------------------
         CASE (NSCARC_DIMENSION_THREE)
         
            ALLOCATE (SC%A(SC%NAE+10), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_MATRIX', 'SC%A', IERR)
            SC%A = 0.0_EB
            
            ALLOCATE (SC%A_COL(SC%NAE+10), STAT=IERR)
            CALL CHKMEMERR ('SCARC_SETUP_MATRIX', 'SC%A_COL', IERR)
            SC%A_COL = 0.0_EB
      

            !!! Compute single matrix entries and corresponding row and column pointers
            !!! Along internal boundaries use placeholders for the neighboring matrix entries
            !!! which will be communicated in a following step
            IP  = 1
            IW0 = 0
            DO K = 1, SC%NZ
               DO J = 1, SC%NY
                  DO I = 1, SC%NX
             
                     IC = (K-1) * SC%NX * SC%NY + (J-1) * SC%NX + I
             
                     !!! main diagonal
                     SC%A(IP)     = - 2.0_EB*SC%DXI2 - 2.0*SC%DYI2 - 2.0_EB*SC%DZI2  
                     SC%A_ROW(IC) = IP                                     
                     SC%A_COL(IP) = IC 
                     IP = IP + 1
            
                     ! lower subdiagonal in z-direction      !!! neighbor in lower k direction ?
                     IF (K > 1) THEN
                        SC%A(IP) = SC%DZI2           
                        SC%A_COL(IP) = IC - SC%NX * SC%NY
                        IP = IP + 1
                     ELSE IF (SC%SUBDIVISION(3,3) > 0) THEN
                        IW0(3) = SC%SUBDIVISION(1,3)
                        IL0(3) = SC%SUBDIVISION(2,3)
                        IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(3),IL0(3))) THEN
                           SC%A_COL(IP) = -IW
                           IP = IP + 1
                        ENDIF
                     ENDIF
     
                     !!! lower subdiagonal in y-direction
                     IF (J > 1) THEN
                        SC%A(IP) =  SC%DYI2                            
                        SC%A_COL(IP) = IC - SC%NX
                        IP = IP + 1
                     ELSE IF (SC%SUBDIVISION(3,2) > 0) THEN      !!! neighbor in lower y direction ?
                        IW0(2) = SC%SUBDIVISION(1,2)
                        IL0(2) = SC%SUBDIVISION(2,2)
                        IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(2),IL0(2))) THEN
                           SC%A_COL(IP) = -IW
                           IP = IP + 1
                        ENDIF
                     ENDIF
     
                     !!! lower subdiagonal in x-direction
                     IF (I > 1) THEN
                        SC%A(IP) = SC%DXI2                            
                        SC%A_COL(IP) = IC - 1
                        IP = IP + 1
                     ELSE IF (SC%SUBDIVISION(3,1) > 0) THEN      !!! neighbor in lower x direction ?
                        IW0(1) = SC%SUBDIVISION(1,1)
                        IL0(1) = SC%SUBDIVISION(2,1)
                        IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(1),IL0(1))) THEN
                           SC%A_COL(IP) = -IW
                           IP = IP + 1
                        ENDIF
                     ENDIF
     
                     ! upper subdiagonal in x-direction
                     IF (I < SC%NX) THEN
                        SC%A(IP) = SC%DXI2           
                        SC%A_COL(IP) = IC + 1
                        IP = IP + 1
                     ELSE IF (SC%SUBDIVISION(3,-1) > 0) THEN      !!! neighbor in upper x direction ?
                        IW0(-1) = SC%SUBDIVISION(1,-1)
                        IL0(-1) = SC%SUBDIVISION(2,-1)
                        IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(-1),IL0(-1))) THEN
                           SC%A_COL(IP) = -IW
                           IP = IP + 1
                        ENDIF
                     ENDIF
     
                     ! upper subdiagonal in y-direction
                     IF (J < SC%NY) THEN
                        SC%A(IP) = SC%DYI2           
                        SC%A_COL(IP) = IC + SC%NX
                        IP = IP + 1
                     ELSE IF (SC%SUBDIVISION(3,-2) > 0) THEN      !!! neighbor in upper y direction ?
                        IW0(-2) = SC%SUBDIVISION(1,-2)
                        IL0(-2) = SC%SUBDIVISION(2,-2)
                        IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(-2),IL0(-2))) THEN
                           SC%A_COL(IP) = -IW
                           IP = IP + 1
                        ENDIF
                     ENDIF
     
                     ! upper subdiagonal in z-direction      
                     IF (K < SC%NZ) THEN
                        SC%A(IP) = SC%DZI2           
                        SC%A_COL(IP) = IC + SC%NX * SC%NY
                        IP = IP + 1
                     ELSE IF (SC%SUBDIVISION(3,-3) > 0) THEN      !!! neighbor in upper z direction ?
                        IW0(-3) = SC%SUBDIVISION(1,-3)
                        IL0(-3) = SC%SUBDIVISION(2,-3)
                        IF (COMPACT_CELL_WITH_NEIGHBOR(SC%WALL, IC,IW,IW0(-3),IL0(-3))) THEN
                           SC%A_COL(IP) = -IW
                           IP = IP + 1
                        ENDIF
                     ENDIF
   
                  ENDDO
               ENDDO
            ENDDO
          
      END SELECT
      SC%A_ROW(SC%NC+1) = IP
      SC%NA             = IP -1                                     ! set correct number of matrix entries

END SELECT

END SUBROUTINE SCARC_SETUP_MATRIX


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if cell (I,J,K) has a neighbor and, if yes, save corresponding IW-value
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
LOGICAL FUNCTION BANDED_CELL_WITH_NEIGHBOR(WALL0, I, J, K, IW, IW0, IL0)
TYPE (SCARC_WALL_TYPE), DIMENSION(:), INTENT(IN):: WALL0
INTEGER, INTENT(IN)    :: I, J, K, IW0, IL0
INTEGER, INTENT(INOUT) :: IW

BANDED_CELL_WITH_NEIGHBOR = .FALSE.

SEARCH_WALLCELL_LOOP: DO IW = IW0, IW0+IL0-1
  IF (I == WALL0(IW)%IXW .AND. J == WALL0(IW)%IYW .AND. K == WALL0(IW)%IZW .AND. WALL0(IW)%NOM /= 0) THEN
     BANDED_CELL_WITH_NEIGHBOR = .TRUE.
     EXIT SEARCH_WALLCELL_LOOP
  ENDIF
ENDDO SEARCH_WALLCELL_LOOP

RETURN
END FUNCTION BANDED_CELL_WITH_NEIGHBOR


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if cell IC has a neighbor and, if yes, save corresponding IW-value
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
LOGICAL FUNCTION COMPACT_CELL_WITH_NEIGHBOR(WALL0, IC, IW, IW0, IL0)
TYPE (SCARC_WALL_TYPE), DIMENSION(:), INTENT(IN):: WALL0
INTEGER, INTENT(IN)    :: IC, IW0, IL0
INTEGER, INTENT(INOUT) :: IW

COMPACT_CELL_WITH_NEIGHBOR = .FALSE.

SEARCH_WALLCELL_LOOP: DO IW = IW0, IW0+IL0-1
  IF (IC == WALL0(IW)%ICW .AND. WALL0(IW)%NOM /= 0) THEN
     COMPACT_CELL_WITH_NEIGHBOR = .TRUE.
     EXIT SEARCH_WALLCELL_LOOP
  ENDIF
ENDDO SEARCH_WALLCELL_LOOP

RETURN
END FUNCTION COMPACT_CELL_WITH_NEIGHBOR

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Extract overlapping matrix data
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_OVERLAPS (NTYPE, NL)
INTEGER, INTENT(IN) :: NTYPE, NL
INTEGER :: NM, NOM
INTEGER :: IERR, IW, IWC, IG, IC, JC, JCA, ICW, ICN, ICE, ICE0, ICE2, ICG, ICG2, ICOL, ICCE, NCOL, NCOL2
INTEGER :: ICC, ICOLG, ICOLE
TYPE (SCARC_TYPE)         , POINTER :: S
TYPE (SCARC_COMPACT_TYPE) , POINTER :: SCF, SCC
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSCF, OSCC

IERR = 0
SELECT_TYPE: SELECT CASE (NTYPE)

   !!! ------------------------------------------------------------------------------------------------
   !!! set stencil sizes on overlapping parts
   !!! ------------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_STENCIL)

      STENCIL_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

         S => SCARC(NM)
         SCF => S%COMPACT(NL)

         STENCIL_EXTERNAL_CELL_LOOP: DO ICE = SCF%NC+1, SCF%NCE
      
           IW = ABS(SCF%WALL_PTR(ICE))

           IF (IW > 0) THEN
              ICG = SCF%WALL(IW)%ICG(1)
           ELSE
              IW  = ABS(IW)
              ICG = SCF%WALL(ABS(IW))%ICG2(1)
           ENDIF

           NOM = SCF%WALL(IW)%NOM
           OSCF => S%OSCARC(NOM)%COMPACT(NL)

           SCF%A_ROW(ICE+1) = SCF%A_ROW(ICE) + OSCF%A_SIZE(ICG)
          
         ENDDO STENCIL_EXTERNAL_CELL_LOOP

      ENDDO STENCIL_MESHES_LOOP

   !!! ------------------------------------------------------------------------------------------------
   !!! after exchange of system matrix
   !!! ------------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_SYSTEM)

      SYSTEM_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
         
         S => SCARC(NM)
         SCF => S%COMPACT(NL)
         
         DO IC = SCF%NC+1, SCF%NCE

            IW = SCF%WALL_PTR(IC)
            IF (IW > 0) THEN
               ICN = SCF%WALL(IW)%ICN(1)
               ICE = SCF%WALL(IW)%ICE(1)
            ELSE
               IW = ABS(IW)
               ICN = SCF%WALL(IW)%ICN2(1)
               ICE = SCF%WALL(IW)%ICE2(1)
            ENDIF

            NOM  = SCF%WALL(IW)%NOM
            OSCF => S%OSCARC(NOM)%COMPACT(NL)

            ICOL = SCF%A_ROW(ICE)
            JC   = ABS(SCF%A_COL(ICOL))

            OSCF%NOM_PTR(JC) = ICE

         ENDDO

         DO IC = SCF%NC+1, SCF%NCE

            IW = SCF%WALL_PTR(IC)
            IF (IW > 0) THEN
              ICN = SCF%WALL(IW)%ICN(1)
            ELSE
              IW = ABS(IW)
              ICN = SCF%WALL(IW)%ICN2(1)
            ENDIF

            NOM = SCF%WALL(IW)%NOM
            OSCF => S%OSCARC(NOM)%COMPACT(NL)

            DO ICOL = SCF%A_ROW(IC),SCF%A_ROW(IC+1)-1
               JC  = SCF%A_COL(ICOL)
               JCA = ABS(SCF%A_COL(ICOL))
               IF (JC < 0 .AND. JCA <= OSCF%NC) THEN
                  IF (OSCF%NOM_PTR(JCA)>0) SCF%A_COL(ICOL) = OSCF%NOM_PTR(JCA)
               ELSE
                  SCF%A_COL(ICOL) = JC
               ENDIF
            ENDDO
         
         ENDDO

      ENDDO SYSTEM_MESHES_LOOP

   !!! ------------------------------------------------------------------------------------------------
   !!! after exchange of prolongation matrix
   !!! ------------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_PROLONGATION)
   
      PROLONGATION_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
         
         S => SCARC(NM)
         SCF => S%COMPACT(NL)
         SCC => S%COMPACT(NL+1)
         
         IG   = 0
         IWC  = 0
         ICCE = SCF%NCC
         PROLONGATION_WALL_LOOP1: DO IW = 1, SCF%NW

            NOM  = SCF%WALL(IW)%NOM
            IF (NOM == 0) CYCLE PROLONGATION_WALL_LOOP1

            OSCF => S%OSCARC(NOM)%COMPACT(NL)
            OSCC => S%OSCARC(NOM)%COMPACT(NL+1)
    
            ICW  = SCF%WALL(IW)%ICW
            ICC  = SCF%CELLTYPE(ICW)

            ICE  = SCF%WALL(IW)%ICE(1)
            ICE2 = SCF%WALL(IW)%ICE2(1)

            ICG  = SCF%WALL(IW)%ICG(1)
            ICG2 = SCF%WALL(IW)%ICG2(1)

            NCOL  = OSCF%P_ROW(ICG +1)-OSCF%P_ROW(ICG)
            NCOL2 = OSCF%P_ROW(ICG2+1)-OSCF%P_ROW(ICG2)

            IF (ICC >= NSCARC_CELLTYPE_COARSE) THEN
               IWC = IWC + 1
               SCC%INTERNAL_BDRY_CELL(ICC) = NSCARC_LAYER_ONE
               SCC%WALL(IWC)%NOM = NOM
               SCC%WALL(IWC)%ICW = ICC
               SCC%WALL(IWC)%IOR = SCF%WALL(IW)%IOR
            ENDIF

            IF (SCF%CELLTYPE(ICE) >= NSCARC_CELLTYPE_COARSE) THEN
               ICCE = ICCE + 1
               SCF%CELLTYPE(ICE) = ICCE
               SCC%EXT_PTR(ICCE) = OSCF%CELLTYPE(ICG)
               ICOL = OSCF%P_ROW(ICG)
               IG  = IG + 1
               OSCF%IG0 = OSCF%IG0 + 1
               OSCC%NOM_PTR(OSCF%P_COL(ICOL)) = ICCE
            ENDIF

            IF (NL/=NLEVEL_MIN .OR. TYPE_LAYER/=NSCARC_LAYER_TWO) CYCLE PROLONGATION_WALL_LOOP1

            IF (SCF%CELLTYPE(ICE2) >= NSCARC_CELLTYPE_COARSE) THEN
               ICCE = ICCE + 1
               SCF%CELLTYPE(ICE2) = ICCE
               SCC%EXT_PTR(ICCE)  = OSCF%CELLTYPE(ICG2)
               ICOL = OSCF%P_ROW(ICG2)
               IG  = IG + 1
               OSCF%IG0 = OSCF%IG0 + 1
               OSCC%NOM_PTR(OSCF%P_COL(ICOL)) = ICCE
            ENDIF

         ENDDO PROLONGATION_WALL_LOOP1

         IF (TYPE_DEBUG >= NSCARC_DEBUG_LESS) THEN
            DO IC = 1, SCC%NC
               WRITE(SCARC_LU,*) 'SCC%INTERNAL_BDRY_CELL(',IC,')=',SCC%INTERNAL_BDRY_CELL(IC)
            ENDDO
         ENDIF

         !!! Replace negative cell numbers of neighboring cells for internal wall cells
         !!! Note that this only holds true for fine grid cells (weights of coarse cells don't reach in the
         !!! neighboring mesh)
         PROLONGATION_WALL_LOOP2: DO IW = 1, SCF%NW

            NOM  = SCF%WALL(IW)%NOM
            IF (NOM == 0) CYCLE PROLONGATION_WALL_LOOP2

            OSCF => S%OSCARC(NOM)%COMPACT(NL)

            ICW  = SCF%WALL(IW)%ICW
            ICC  = SCF%CELLTYPE(ICW)

            IF (ICC < NSCARC_CELLTYPE_COARSE) THEN

               DO ICOL = SCF%P_ROW(ICW), SCF%P_ROW(ICW+1)-1
                  JC   = SCF%P_COL(ICOL)
                  IF (JC < 0) THEN
                     IC = OSCF%NOM_PTR(ABS(JC))
                     SCF%P_COL(ICOL) = SCF%CELLTYPE(IC)

                  !!! Additionally identify coarse cells from second layer adjacent to internal boundary 
                  ELSE IF (JC <= SCF%NCC) THEN
                     IF (SCC%INTERNAL_BDRY_CELL(JC) /= NSCARC_LAYER_ONE) THEN
                        IWC = IWC + 1
                        SCC%INTERNAL_BDRY_CELL(JC) = NSCARC_LAYER_TWO
                        SCC%WALL(IWC)%NOM = NOM
                        SCC%WALL(IWC)%ICW = JC
                        SCC%WALL(IWC)%IOR = SCF%WALL(IW)%IOR
                     ENDIF
                  ENDIF
               ENDDO
            ENDIF
         ENDDO PROLONGATION_WALL_LOOP2

         PROLONGATION_ECELL_LOOP: DO ICE0 = SCF%NC+1, SCF%NCE

            IW  = SCF%WALL_PTR(ICE0)
            NOM = SCF%WALL(ABS(IW))%NOM
            OSCF => S%OSCARC(NOM)%COMPACT(NL)


            !!! Replace positive cell numbers of neighboring cells in first layer
            IF (IW > 0) THEN
               ICG = SCF%WALL(IW)%ICG(1)
               ICE = SCF%WALL(IW)%ICE(1)
               ICOLE = SCF%P_ROW(ICE)
               DO ICOLG = OSCF%P_ROW(ICG), OSCF%P_ROW(ICG+1)-1
                  JC    = OSCF%P_COL(ICOLG)
                  IF (JC > 0 .AND. JC <= OSCF%NCC) THEN
                     IC = OSCC%NOM_PTR(JC)
                     OSCF%P_COL(ICOLG) = IC
                     SCF%P_COL(ICOLE)  = IC
                  ELSE
                     OSCF%P_COL(ICOLG) = SCF%CELLTYPE(ABS(JC))
                     SCF%P_COL(ICOLE) = SCF%CELLTYPE(ABS(JC))
                  ENDIF
                  SCF%P(ICOLE) = OSCF%P(ICOLG)
                  ICOLE = ICOLE + 1
               ENDDO
               SCF%P_ROW(ICE+1) = ICOLE
   
            !!! Replace positive cell numbers of neighboring cells in second layer (if requested)
            ELSE
               IW = ABS(IW)
               IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
                  ICG2 = SCF%WALL(IW)%ICG2(1)
                  ICE2 = SCF%WALL(IW)%ICE2(1)
                  ICOLE = SCF%P_ROW(ICE2)
                  DO ICOLG = OSCF%P_ROW(ICG2), OSCF%P_ROW(ICG2+1)-1
                     JC   = OSCF%P_COL(ICOLG)
                     IF (JC > 0 .AND. JC <= OSCF%NCC) THEN
                        IC = OSCC%NOM_PTR(JC)
                        IF (IC > 0) THEN
                           OSCF%P_COL(ICOLG) = IC
                           SCF%P_COL(ICOLE) = IC
                        ELSE
                           OSCF%P_COL(ICOLG) = -OSCF%P_COL(ICOLG)
                           SCF%P_COL(ICOLE)  =  OSCF%P_COL(ICOLG)
                        ENDIF
                     ELSE
                        OSCF%P_COL(ICOLG) = SCF%CELLTYPE(ABS(JC))
                        SCF%P_COL(ICOLE) = SCF%CELLTYPE(ABS(JC))
                     ENDIF
                     SCF%P(ICOLE) = OSCF%P(ICOLG)
                     ICOLE = ICOLE + 1
                  ENDDO
                  SCF%P_ROW(ICE2+1) = ICOLE
               ENDIF
            ENDIF
            
         ENDDO PROLONGATION_ECELL_LOOP

      ENDDO PROLONGATION_MESHES_LOOP

END SELECT SELECT_TYPE

END SUBROUTINE SCARC_SETUP_OVERLAPS


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set pointer for different structures on level NL
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_BOUNDARY (NM, NL)
INTEGER, INTENT(IN) :: NM, NL
INTEGER :: I, J, K, IOR0, IW, IC, NOM, IP
REAL(EB) :: DBC
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC


SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

   !!!----------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      SB  => SCARC(NM)%BANDED(NL)

      SELECT_DIMENSION_BANDED: SELECT CASE (TYPE_DIMENSION)
      
         !!!------------------ 2D ---------------------------
         CASE (NSCARC_DIMENSION_TWO)
      
            WALLCELL_LOOP2D_BANDED: DO IW = 1, SB%NW
             
               IOR0 = SB%WALL(IW)%IOR
               IF (ABS(IOR0) == 2) CYCLE            ! 2D: in case of y-boundary cycle
         
               I   = SB%WALL(IW)%IXW
               K   = SB%WALL(IW)%IZW

               NOM = SB%WALL(IW)%NOM
         
               SB%WALL(IW)%ICW = (K-1)*SB%NX + I
      
               SELECT CASE (IOR0)
                  CASE (1)
                     IC = (K-1) * SB%NX + I
                     DBC= SB%DXI2
                  CASE (-1)
                     IC = K * SB%NX
                     DBC= SB%DXI2
                  CASE (3)
                     IC = I
                     DBC= SB%DZI2
                  CASE (-3)
                     IC = (SB%NZ-1) * SB%NX + I
                     DBC= SB%DZI2
               END SELECT
         
               SELECT CASE (SB%WALL(IW)%BTYPE)
                  CASE (DIRICHLET)                        ! set Dirichlet BC's along open boundary cells
                    SB%A(IC,ID) = SB%A(IC,ID) - DBC
                  !CASE (INTERNAL)                        ! do nothing along internal boundaries (only debugging)
                  CASE (NEUMANN)                          ! set Neumann BC's at all other nodes
                    SB%A(IC,ID) = SB%A(IC,ID) + DBC
               END SELECT
         
            ENDDO WALLCELL_LOOP2D_BANDED

        
         !!!------------------ 3D ---------------------------
         CASE (NSCARC_DIMENSION_THREE)
      
            WALLCELL_LOOP3D_BANDED: DO IW = 1, SB%NW
         
               IOR0 = SB%WALL(IW)%IOR

               I    = SB%WALL(IW)%IXW
               J    = SB%WALL(IW)%IYW
               K    = SB%WALL(IW)%IZW

               NOM  = SB%WALL(IW)%NOM
         
               SB%WALL(IW)%ICW = (K-1)*SB%NX*SB%NY + (J-1)*SB%NX + I
      
               SELECT CASE (IOR0)
                  CASE (1)
                     IC = (K-1) * SB%NX * SB%NY + (J-1) * SB%NX + I
                     DBC= SB%DXI2
                  CASE (-1)
                     IC = (K-1) * SB%NX * SB%NY + J * SB%NX 
                     DBC= SB%DXI2
                  CASE (2)
                     IC = (K-1) * SB%NX * SB%NY + I
                     DBC= SB%DYI2
                  CASE (-2)
                     IC = (K-1) * SB%NX * SB%NY + (SB%NY-1) * SB%NX + I
                     DBC= SB%DYI2
                  CASE (3)
                     IC = (J-1) * SB%NX + I
                     DBC= SB%DZI2
                  CASE (-3)
                     IC = (SB%NZ-1) * SB%NX * SB%NY + (J-1) * SB%NX + I
                     DBC= SB%DZI2
               END SELECT
         
               SELECT CASE (SB%WALL(IW)%BTYPE)
                  CASE (DIRICHLET)                     ! set Dirichlet BC's at open and null boundary cells
                     SB%A(IC,ID) = SB%A(IC,ID) - DBC
                  !CASE (INTERNAL)                     ! do nothing along internal boundaries (only debugging)
                  CASE (NEUMANN)                       ! set Neumann BC's at all other cells
                     SB%A(IC,ID) = SB%A(IC,ID) + DBC
               END SELECT
         
            ENDDO WALLCELL_LOOP3D_BANDED
           
      END SELECT SELECT_DIMENSION_BANDED


   !!!----------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      SC => SCARC(NM)%COMPACT(NL)

      SELECT_DIMENSION_COMPACT: SELECT CASE (TYPE_DIMENSION)
      
         !!!------------------ 2D ---------------------------
         CASE (NSCARC_DIMENSION_TWO)
      
            WALLCELL_LOOP2D_COMPACT: DO IW = 1, SC%NW
             
               IOR0 = SC%WALL(IW)%IOR
               IF (ABS(IOR0) == 2) CYCLE            ! 2D: in case of y-boundary cycle
         
               I    = SC%WALL(IW)%IXW
               K    = SC%WALL(IW)%IZW

               NOM  = SC%WALL(IW)%NOM
         
               SC%WALL(IW)%ICW = (K-1)*SC%NX + I
      
               SELECT CASE (IOR0)
                  CASE (1)
                     IC = (K-1) * SC%NX + I
                     DBC= SC%DXI2
                  CASE (-1)
                     IC = K * SC%NX
                     DBC= SC%DXI2
                  CASE (3)
                     IC = I
                     DBC= SC%DZI2
                  CASE (-3)
                     IC = (SC%NZ-1) * SC%NX + I
                     DBC= SC%DZI2
               END SELECT
         
               IP = SC%A_ROW(IC)
               SELECT CASE (SC%WALL(IW)%BTYPE)
                  CASE (DIRICHLET)                        ! set Dirichlet BC's along open boundary cells
                     SC%A(IP) = SC%A(IP) - DBC
                  !CASE (INTERNAL)                        ! do nothing along internal boundaries (only debugging)
                  CASE (NEUMANN)                          ! set Neumann BC's at all other nodes
                     SC%A(IP) = SC%A(IP) + DBC
               END SELECT
         
            ENDDO WALLCELL_LOOP2D_COMPACT
         
      
         !!!------------------ 2D ---------------------------
         CASE (NSCARC_DIMENSION_THREE)
      
            WALLCELL_LOOP3D_COMPACT: DO IW = 1, SC%NW
         
               IOR0 = SC%WALL(IW)%IOR

               I    = SC%WALL(IW)%IXW
               J    = SC%WALL(IW)%IYW
               K    = SC%WALL(IW)%IZW

               NOM  = SC%WALL(IW)%NOM
         
               SC%WALL(IW)%ICW = (K-1)*SC%NX*SC%NY + (J-1)*SC%NX + I
      
               SELECT CASE (IOR0)
                  CASE (1)
                     IC = (K-1) * SC%NX * SC%NY + (J-1) * SC%NX + I
                     DBC= SC%DXI2
                  CASE (-1)
                     IC = (K-1) * SC%NX * SC%NY + J * SC%NX 
                     DBC= SC%DXI2
                  CASE (2)
                     IC = (K-1) * SC%NX * SC%NY + I
                     DBC= SC%DYI2
                  CASE (-2)
                     IC = (K-1) * SC%NX * SC%NY + (SC%NY-1) * SC%NX + I
                     DBC= SC%DYI2
                  CASE (3)
                     IC = (J-1) * SC%NX + I
                     DBC= SC%DZI2
                  CASE (-3)
                     IC = (SC%NZ-1) * SC%NX * SC%NY + (J-1) * SC%NX + I
                     DBC= SC%DZI2
               END SELECT
         
               IP = SC%A_ROW(IC)
               SELECT CASE (SC%WALL(IW)%BTYPE)
                  CASE (DIRICHLET)                        ! set Dirichlet BC's at open and null boundary cells
                     SC%A(IP) = SC%A(IP) - DBC
                  !CASE (INTERNAL)                        ! do nothing along internal boundaries (only debugging)
                  CASE (NEUMANN)                          ! set Neumann BC's at all other cells
                     SC%A(IP) = SC%A(IP) + DBC
               END SELECT
         
            ENDDO WALLCELL_LOOP3D_COMPACT
           
      END SELECT SELECT_DIMENSION_COMPACT

END SELECT SELECT_SYSTEM

END SUBROUTINE SCARC_SETUP_BOUNDARY


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Initialize global solver methods (CG/BICG/GMG/AMG) and corresponding level structures
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_VECTORS
INTEGER :: IERR, IBP1, JBP1, KBP1
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC
TYPE (SCARC_PRECON_TYPE) , POINTER :: SP
INTEGER :: NM, NL

IERR = 0

MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
   LEVEL_LOOP: DO NL = NLEVEL_MIN, NLEVEL_MAX

      SELECT_STORAGE: SELECT CASE (TYPE_SYSTEM) 
      
         !!!-------------------------------------------------------------------------------------------------
         !!! Bandwise storage technique
         !!!-------------------------------------------------------------------------------------------------
         CASE (NSCARC_SYSTEM_BANDED)
            
            !!! let SB point to SYSTEM-BANDED structure
            SB => SCARC(NM)%BANDED(NL)
         
            IBP1 = SB%NX + 1
            JBP1 = SB%NY + 1
            KBP1 = SB%NZ + 1
      
            SELECT_METHOD_BANDED: SELECT CASE (TYPE_METHOD)
         
               !!! working and auxiliary vectors for global CG/BICG-method
               CASE (NSCARC_METHOD_KRYLOV)
         
                  ALLOCATE (SB%X(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'X', IERR)
                  SB%X = 0.0_EB
             
                  ALLOCATE (SB%F(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'B', IERR)
                  SB%F = 0.0_EB
             
                  ALLOCATE (SB%D(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'D', IERR)
                  SB%D = 0.0_EB
         
                  ALLOCATE (SB%W(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'W', IERR)
                  SB%W = 0.0_EB
             
                  ALLOCATE (SB%G(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'G', IERR)
                  SB%G = 0.0_EB
             
                  ALLOCATE (SB%Y(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'Y', IERR)
                  SB%Y = 0.0_EB
         
                  ALLOCATE (SB%Z(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'Z', IERR)
                  SB%Z = 0.0_EB
         
         
                  IF (TYPE_PRECON == NSCARC_PRECON_MULTIGRID) THEN
               
                     ALLOCATE (SB%X2(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'X2', IERR)
                     SB%X2 = 0.0_EB
               
                     ALLOCATE (SB%D2(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'D2', IERR)
                     SB%D2 = 0.0_EB
         
                     IF (NL==NLEVEL_MAX) THEN
            
                        ALLOCATE (SB%W2(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                        CALL CHKMEMERR ('SCARC', 'W2', IERR)
                        SB%W2 = 0.0_EB
                
                        ALLOCATE (SB%G2(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                        CALL CHKMEMERR ('SCARC', 'G2', IERR)
                        SB%G2 = 0.0_EB
                
                        ALLOCATE (SB%Y2(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                        CALL CHKMEMERR ('SCARC', 'Y2', IERR)
                        SB%Y2 = 0.0_EB
            
                     ENDIF
                   
                  ENDIF
         
                  IF (TYPE_PRECON == NSCARC_PRECON_FFT) THEN 
                     SP => SCARC(NM)%PRECON(NL)
                     ALLOCATE (SP%FFT(1:IBP1, 1:JBP1, 1:KBP1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'FFT', IERR)
                     SP%FFT = 0.0_EB
                  ENDIF
         
               !!! working and auxiliary vectors for global GMG/AMG-method
               CASE (NSCARC_METHOD_MULTIGRID)
         
                  ALLOCATE (SB%X(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'X', IERR)
                  SB%X = 0.0_EB
             
                  ALLOCATE (SB%F(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'B', IERR)
                  SB%F = 0.0_EB
             
                  ALLOCATE (SB%D(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'D', IERR)
                  SB%D = 0.0_EB
         
                  IF (NL==NLEVEL_MAX) THEN
         
                     ALLOCATE (SB%W(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'W', IERR)
                     SB%W = 0.0_EB
             
                     ALLOCATE (SB%G(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'G', IERR)
                     SB%G = 0.0_EB
             
                     ALLOCATE (SB%Y(0:IBP1, 0:JBP1, 0:KBP1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'Y', IERR)
                     SB%Y = 0.0_EB
         
                  ENDIF
         
                  IF (TYPE_PRECON == NSCARC_PRECON_FFT) THEN
                     SP => SCARC(NM)%PRECON(NL)
                     ALLOCATE (SP%FFT(1:IBP1, 1:JBP1, 1:KBP1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'FFT', IERR)
                     SP%FFT = 0.0_EB
                  ENDIF
         
            END SELECT SELECT_METHOD_BANDED
            
      
         !!!-------------------------------------------------------------------------------------------------
         !!! Compact storage technique
         !!!-------------------------------------------------------------------------------------------------
         CASE (NSCARC_SYSTEM_COMPACT)
      
            SC => SCARC(NM)%COMPACT(NL)
         
            SELECT_METHOD_COMPACT: SELECT CASE (TRIM(SCARC_METHOD))
         
               !!! working and auxiliary vectors for global CG/BICG-method
               CASE ('KRYLOV')
         
                  ALLOCATE (SC%X(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'X', IERR)
                  SC%X = 0.0_EB
             
                  ALLOCATE (SC%F(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'B', IERR)
                  SC%F = 0.0_EB
             
                  ALLOCATE (SC%D(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'D', IERR)
                  SC%D = 0.0_EB
         
                  ALLOCATE (SC%W(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'W', IERR)
                  SC%W = 0.0_EB
             
                  ALLOCATE (SC%G(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'G', IERR)
                  SC%G = 0.0_EB
             
                  ALLOCATE (SC%Y(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'Y', IERR)
                  SC%Y = 0.0_EB
         
                  ALLOCATE (SC%Z(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'Z', IERR)
                  SC%Z = 0.0_EB
      
                  IF (TYPE_PRECON == NSCARC_PRECON_MULTIGRID) THEN
      
                     ALLOCATE (SC%X2(SC%NCE), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'X2', IERR)
                     SC%X2 = 0.0_EB
               
                     ALLOCATE (SC%D2(SC%NCE), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'D2', IERR)
                     SC%D2 = 0.0_EB
         
                     IF (NL==NLEVEL_MAX) THEN
            
                        ALLOCATE (SC%W2(SC%NCE), STAT=IERR)
                        CALL CHKMEMERR ('SCARC', 'W2', IERR)
                        SC%W2 = 0.0_EB
                
                        ALLOCATE (SC%G2(SC%NCE), STAT=IERR)
                        CALL CHKMEMERR ('SCARC', 'G2', IERR)
                        SC%G2 = 0.0_EB
                
                        ALLOCATE (SC%Y2(SC%NCE), STAT=IERR)
                        CALL CHKMEMERR ('SCARC', 'Y2', IERR)
                        SC%Y2 = 0.0_EB
            
                     ENDIF
                   
                  ENDIF
         
                  IF (TYPE_PRECON == NSCARC_PRECON_FFT) THEN
                     SP => SCARC(NM)%PRECON(NL)
                     ALLOCATE (SP%FFT(1:SC%NX+1, 1:SC%NY+1, 1:SC%NZ+1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'FFT', IERR)
                     SP%FFT = 0.0_EB
                  ENDIF
         
               !!! working and auxiliary vectors for global GMG/AMG-method
               CASE ('MULTIGRID')
         
                  ALLOCATE (SC%X(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'X', IERR)
                  SC%X = 0.0_EB
             
                  ALLOCATE (SC%F(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'F', IERR)
                  SC%F = 0.0_EB
             
                  ALLOCATE (SC%D(SC%NCE), STAT=IERR)
                  CALL CHKMEMERR ('SCARC', 'D', IERR)
                  SC%D = 0.0_EB
         
                  IF (NL==NLEVEL_MAX) THEN
         
                     ALLOCATE (SC%W(SC%NCE), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'W', IERR)
                     SC%W = 0.0_EB
             
                     ALLOCATE (SC%G(SC%NCE), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'G', IERR)
                     SC%G = 0.0_EB
             
                     ALLOCATE (SC%Y(SC%NCE), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'Y', IERR)
                     SC%Y = 0.0_EB
         
                  ENDIF
         
                  IF (TYPE_PRECON == NSCARC_PRECON_FFT) THEN
                     SP => SCARC(NM)%PRECON(NL)
                     ALLOCATE (SP%FFT(1:SC%NX+1, 1:SC%NY+1, 1:SC%NZ+1), STAT=IERR)
                     CALL CHKMEMERR ('SCARC', 'FFT', IERR)
                     SP%FFT = 0.0_EB
                  ENDIF
         
            END SELECT SELECT_METHOD_COMPACT
      
      END SELECT SELECT_STORAGE

   ENDDO LEVEL_LOOP
ENDDO  MESHES_LOOP

END SUBROUTINE SCARC_SETUP_VECTORS

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set sizes for transfer matrices
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE  SCARC_SETUP_SIZES(NTYPE, NL)
INTEGER, INTENT(IN) :: NTYPE, NL
INTEGER :: IW, IC, IG, ICP, ICE, ICE2, IERR, ICCE
INTEGER :: NM, NOM
TYPE (OSCARC_TYPE), POINTER :: OS
TYPE (SCARC_BANDED_TYPE)  , POINTER :: SBF
TYPE (SCARC_COMPACT_TYPE) , POINTER :: SCF, SCC
TYPE (OSCARC_BANDED_TYPE) , POINTER :: OSBF
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSCF, OSCC


SELECT CASE (NTYPE)

   !!!------------------------------------------------------------------------------------------------------
   !!! Define sizes for banded system matrix A (including extended regions related to overlaps)
   !!!------------------------------------------------------------------------------------------------------
   CASE (NSCARC_SIZE_MATRIXB)

      BANDED_SYSTEM_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SBF => SCARC(NM)%BANDED(NL)
      
         !!! Determine number of couplings in matrix stencil and matrix size in own part of mesh
         SELECT CASE (TYPE_DIMENSION)
            CASE (NSCARC_DIMENSION_TWO)
               SBF%NCPL = 5
            CASE (NSCARC_DIMENSION_THREE)
               SBF%NCPL = 7
         END SELECT
         SBF%NA = SBF%NC * SBF%NCPL

         !!! Determine sizes of overlapped parts for later communication with corresponding neighbors
         DO IW = 1, SBF%NW
            NOM = SBF%WALL(IW)%NOM
            IF (NOM /= 0) THEN
      
               OSBF => SCARC(NM)%OSCARC(NOM)%BANDED(NL)
      
               IC = SBF%WALL(IW)%ICW
               OSBF%NA0 = OSBF%NA0 + SBF%NCPL
      
               IF (TYPE_LAYER == NSCARC_LAYER_TWO) THEN
                  IC = SBF%WALL(IW)%ICW2
                  OSBF%NA0 = OSBF%NA0 + SBF%NCPL
               ENDIF

            ENDIF
         ENDDO
      
      ENDDO BANDED_SYSTEM_MESHES_LOOP
      
      !!! Exchange sizes for AMG matrices and vectors
      IF (NMESHES > 1)  CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_SIZE_MATRIXB, NL)
      
      
      !!! Determine extended sizes for extendes prolongation and restriction matrix
      BANDED_SYSTEM_MESHES_LOOP2: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SBF => SCARC(NM)%BANDED(NL)
         SBF%NAE = SBF%NA
      
         BANDED_OTHER_MESHES_LOOP2: DO NOM = 1, NMESHES
      
            IF (NOM == NM) CYCLE BANDED_OTHER_MESHES_LOOP2
            OS => SCARC(NM)%OSCARC(NOM)
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE BANDED_OTHER_MESHES_LOOP2
      
            OSBF => SCARC(NM)%OSCARC(NOM)%BANDED(NL)
      
            SBF%NAE  = SBF%NAE  + OSBF%NA
      
         ENDDO BANDED_OTHER_MESHES_LOOP2
      
      ENDDO BANDED_SYSTEM_MESHES_LOOP2
      
   !!!------------------------------------------------------------------------------------------------------
   !!! Define sizes for system matrix A (including extended regions related to overlaps)
   !!!------------------------------------------------------------------------------------------------------
   CASE (NSCARC_SIZE_MATRIXC)

      COMPACT_SYSTEM_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SCF => SCARC(NM)%COMPACT(NL)
      
         !!! Determine number of couplings in matrix stencil and matrix size in own part of mesh
         SELECT CASE (TYPE_DIMENSION)
            CASE (NSCARC_DIMENSION_TWO)
               SCF%NCPL = 5
            CASE (NSCARC_DIMENSION_THREE)
               SCF%NCPL = 7
         END SELECT
         SCF%NA = SCF%NC * SCF%NCPL

         !!! Determine sizes of overlapped parts for later communication with corresponding neighbors
         DO IW = 1, SCF%NW
            NOM = SCF%WALL(IW)%NOM
            IF (NOM /= 0) THEN
      
               OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
      
               IC = SCF%WALL(IW)%ICW
               OSCF%NA0 = OSCF%NA0 + SCF%NCPL
      
               IF (TYPE_LAYER == NSCARC_LAYER_TWO) THEN
                  IC = SCF%WALL(IW)%ICW2
                  OSCF%NA0 = OSCF%NA0 + SCF%NCPL
               ENDIF

            ENDIF
         ENDDO
      
      ENDDO COMPACT_SYSTEM_MESHES_LOOP
      
      !!! Exchange sizes for AMG matrices and vectors
      IF (NMESHES > 1) CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_SIZE_MATRIXC, NL)
      
      
      !!! Determine extended sizes for extendes prolongation and restriction matrix
      COMPACT_SYSTEM_MESHES_LOOP2: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SCF => SCARC(NM)%COMPACT(NL)
         SCF%NAE = SCF%NA
      
         COMPACT_OTHER_MESHES_LOOP2: DO NOM = 1, NMESHES
      
            IF (NOM == NM) CYCLE COMPACT_OTHER_MESHES_LOOP2
            OS => SCARC(NM)%OSCARC(NOM)
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE COMPACT_OTHER_MESHES_LOOP2
      
            OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
            SCF%NAE  = SCF%NAE  + OSCF%NA
      
            ALLOCATE (OSCF%A_SIZE(1:OSCF%NG), STAT=IERR)
            CALL CHKMEMERR ('SCARC', 'OSCF%A_SIZE', IERR)
            OSCF%A_SIZE = 0

         ENDDO COMPACT_OTHER_MESHES_LOOP2
      
      ENDDO COMPACT_SYSTEM_MESHES_LOOP2
      
   !!!------------------------------------------------------------------------------------------------------
   !!! Define sizes for transfer matrices P and R (including extended regions related to overlaps)
   !!!------------------------------------------------------------------------------------------------------
   CASE (NSCARC_SIZE_TRANSFERC)


      TRANSFER_MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SCF => SCARC(NM)%COMPACT(NL)
         SCC => SCARC(NM)%COMPACT(NL+1)
         
         !!! Determine dimensions of restriction and prolongation matrices in own mesh
         SCF%NCF  = 0
         SCF%NCC  = 0
         SCF%NP   = 0
         SCF%NR   = 0
         SCF%NCCI = 0
         SCF%NCCE = SCF%NCC
         SCF%NCE0 = SCF%NC+1
      
         DO IC = 1, SCF%NC
            SELECT CASE (SCF%CELLTYPE(IC))
               CASE (NSCARC_CELLTYPE_COARSE)
                  SCF%NCC = SCF%NCC + 1
                  SCF%NP  = SCF%NP  + 1
                  SCF%NR  = SCF%NP
               CASE (NSCARC_CELLTYPE_SFINE, NSCARC_CELLTYPE_WFINE)
                  SCF%NCF = SCF%NCF + 1
                  SCF%NP  = SCF%NP  + SCF%A_ROW(IC+1)-SCF%A_ROW(IC) - 1
                  SCF%NR  = SCF%NP
            END SELECT
         ENDDO
         SCF%NCCI = SCF%NCC
      
         !!! Determine number of coarse and fine cells and check correctness of computation
         IF (SCF%NCC + SCF%NCF /= SCF%NC) THEN
            WRITE(*,*) 'Error in AMG standard coarsening, N_CELLS_COARSE + N_CELLS_FINE = ', SCF%NCC + SCF%NCF, &
                       ' differs from N_CELLS = ', SCF%NC, ' on level ', NL
         !   STOP
         ENDIF
         
         !!! define some variables in overlapping part
         TRANSFER_OTHER_MESHES_LOOP: DO NOM = 1, NMESHES
      
            IF (NOM == NM) CYCLE TRANSFER_OTHER_MESHES_LOOP
            OS => SCARC(NM)%OSCARC(NOM)
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE TRANSFER_OTHER_MESHES_LOOP
      
            OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
            OSCF%NP   = 0
            OSCF%NR   = 0
            OSCF%NP0  = 0
            OSCF%NR0  = 0
            OSCF%NCC  = 0
            OSCF%NCF  = 0
            OSCF%NCC0 = 0
            OSCF%NCF0 = 0
            OSCF%IG0  = 0
      
         ENDDO TRANSFER_OTHER_MESHES_LOOP
      
         !!! Determine sizes of overlapped parts for later communication with corresponding neighbors
         ICCE = SCF%NCC
         SCF%NCW = 0
         DO IW = 1, SCF%NW
            NOM = SCF%WALL(IW)%NOM
            IF (NOM /= 0) THEN
      
               SCF%NCW = SCF%NCW + 1
               OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
      
               IC  = SCF%WALL(IW)%ICW
               ICE = SCF%WALL(IW)%ICE(1)
               SELECT CASE (SCF%CELLTYPE(IC))
                  CASE (NSCARC_CELLTYPE_COARSE)
                     OSCF%NP0  = OSCF%NP0  + 1
                     OSCF%NR0  = OSCF%NP0
                     OSCF%NCC0 = OSCF%NCC0 + 1
                  CASE (NSCARC_CELLTYPE_SFINE, NSCARC_CELLTYPE_WFINE)
                     OSCF%NP0  = OSCF%NP0  + SCF%A_ROW(IC+1)-SCF%A_ROW(IC) - 1
                     OSCF%NR0  = OSCF%NP0  
                     OSCF%NCF0 = OSCF%NCF0 + 1
               END SELECT
               OSCF%NW0 = OSCF%NW0 + 1                ! OSCF%NW0 is increased anyway
      
               IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
                  IC   = SCF%WALL(IW)%ICW2
                  ICE2 = SCF%WALL(IW)%ICE2(1)
                  SELECT CASE (SCF%CELLTYPE(IC))
                     CASE (NSCARC_CELLTYPE_COARSE)
                        OSCF%NCC0 = OSCF%NCC0 + 1
                        OSCF%NP0  = OSCF%NP0  + 1
                        OSCF%NR0  = OSCF%NP0
                     CASE (NSCARC_CELLTYPE_SFINE, NSCARC_CELLTYPE_WFINE)
                        OSCF%NCF0 = OSCF%NCF0 + 1
                        OSCF%NP0  = OSCF%NP0  + SCF%A_ROW(IC+1)-SCF%A_ROW(IC) - 1
                        OSCF%NR0  = OSCF%NP0
                  END SELECT
               ENDIF
      
            ENDIF
         ENDDO

         !!!
         !!! Determine new numbering for coarse cells in interior of mesh
         !!!
         ICP   = 0
         DO IC = 1, SCF%NC
            IF (SCF%CELLTYPE(IC) == NSCARC_CELLTYPE_COARSE) THEN
               ICP = ICP + 1
               SCF%CELLTYPE(IC) = ICP
            ENDIF
         ENDDO
      
      ENDDO TRANSFER_MESHES_LOOP
      
      !!! Exchange sizes for AMG matrices and vectors
      IF (NMESHES > 1)  CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_SIZE_TRANSFERC, NL)
      
      !!! Determine extended sizes for extendes prolongation and restriction matrix
      TRANSFER_MESHES_LOOP2: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SCF => SCARC(NM)%COMPACT(NL)

         SCF%NPE  = SCF%NP
         SCF%NRE  = SCF%NR
         SCF%NCCE = SCF%NCC
         SCF%NCFE = SCF%NCF
      
         TRANSFER_OTHER_MESHES_LOOP2: DO NOM = 1, NMESHES
      
            IF (NOM == NM) CYCLE TRANSFER_OTHER_MESHES_LOOP2
            OS => SCARC(NM)%OSCARC(NOM)
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE TRANSFER_OTHER_MESHES_LOOP2

            OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
            OSCC => SCARC(NM)%OSCARC(NOM)%COMPACT(NL+1)
            OSCC%NC = OSCF%NCC

            ALLOCATE (OSCC%GHOST_PTR(1:OSCC%NC), STAT=IERR)
            CALL CHKMEMERR ('SCARC', 'OSCC%GHOST_PTR', IERR)
            OSCC%GHOST_PTR = 0

            ALLOCATE (OSCC%NOM_PTR(1:OSCF%NCCI), STAT=IERR)
            CALL CHKMEMERR ('SCARC', 'OSCC%NOM_PTR', IERR)
            OSCC%NOM_PTR = 0

            DO IG = 1, OSCF%NCC
                OSCC%GHOST_PTR(IG) = SCF%NCCE + IG
            ENDDO
      
            SCF%NPE  = SCF%NPE  + OSCF%NP
            SCF%NRE  = SCF%NRE  + OSCF%NR
            SCF%NCCE = SCF%NCCE + OSCF%NCC
            SCF%NCFE = SCF%NCFE + OSCF%NCF
      
         ENDDO TRANSFER_OTHER_MESHES_LOOP2

      ENDDO TRANSFER_MESHES_LOOP2

      !!! Determine extended sizes for extendes prolongation and restriction matrix
      TRANSFER_MESHES_LOOP3: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SCF => SCARC(NM)%COMPACT(NL)
         SCC => SCARC(NM)%COMPACT(NL+1)

         SCC%NC  = SCF%NCC
         SCC%NCE = SCF%NCCE
         SCC%NW  = SCF%NCW

         ALLOCATE (SCC%WALL(1:SCC%NW), STAT=IERR)
         CALL CHKMEMERR ('SCARC', 'SCC%WALL', IERR)

         ALLOCATE (SCC%CELLTYPE(1:SCC%NCE), STAT=IERR)
         CALL CHKMEMERR ('SCARC', 'SCC%CELLTYPE', IERR)
         SCC%CELLTYPE = NSCARC_CELLTYPE_NONE

         ALLOCATE (SCC%MEASURE(1:SCC%NCE), STAT=IERR)
         CALL CHKMEMERR ('SCARC', 'SCC%MEASURE', IERR)
         SCC%MEASURE = NSCARC_MEASURE_NONE

         ALLOCATE(SCC%INTERNAL_BDRY_CELL(SCC%NC), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','INTERNAL_BDRY_CELL',IERR)
         SCC%INTERNAL_BDRY_CELL = NSCARC_LAYER_NONE

!WRITE(*,*) 'ALLOCATING SCC%WALL_PTR in length ', SCC%NC+1, ' to ', SCC%NCE
         ALLOCATE(SCC%WALL_PTR(SCC%NC+1:SCC%NCE), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','WALL_PTR',IERR)

         ALLOCATE(SCC%EXT_PTR(SCC%NC+1:SCC%NCE), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_WALLINFO','EXT_PTR',IERR)

      ENDDO TRANSFER_MESHES_LOOP3

END SELECT

END SUBROUTINE SCARC_SETUP_SIZES



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Initialize global 3D-solver methods (cg/mg)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_COARSENING 
INTEGER :: IERR, NL, NM, NOM, IC, ICC
TYPE (SCARC_COMPACT_TYPE), POINTER :: SCF, SCC
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSCF, OSCC
TYPE (OSCARC_TYPE), POINTER :: OSF

IERR = 0

IF (TYPE_MULTIGRID /= NSCARC_MULTIGRID_ALGEBRAIC) RETURN

CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_ACELL , NLEVEL_MIN,'SETUP_COARSENING','WALL_CELL')
CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIX, NLEVEL_MIN,'SETUP_COARSENING', 'MATRIX')


!!! Determine number of multigrid levels
LEVEL_LOOP: DO NL = NLEVEL_MIN, NLEVEL_MAX-1
   
   !!!-------------------------------------------------------------------------------------------------
   !!! Determine coarser meshes corresponding to requested coarsening strategy
   !!!  --- allocate necessary arrays
   !!!  --- setup measures of single cells
   !!!  --- setup celltypes of single cells
   !!!  --- setup sizes of transformation matrices (prolongation/restriction)
   !!!-------------------------------------------------------------------------------------------------
   !IF (NL == NLEVEL_MIN) THEN

   DO NM = NMESHES_MIN, NMESHES_MAX

      SCF => SCARC(NM)%COMPACT(NL)                       

      ALLOCATE (SCF%MEASURE(1:SCF%NCE), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'SCF%MEASURE', IERR)
      SCF%MEASURE = 0.0_EB

      ALLOCATE (SCF%CELLTYPE(1:SCF%NCE), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'SCF%CELLTYPE', IERR)
      SCF%CELLTYPE = NSCARC_CELLTYPE_NONE

      OTHER_MESH_LOOP1: DO NOM = 1, NMESHES

         IF (NOM == NM) CYCLE OTHER_MESH_LOOP1

         OSF  => SCARC(NM)%OSCARC(NOM)      
         IF (OSF%NICMAX_S==0 .AND. OSF%NICMAX_R==0) CYCLE OTHER_MESH_LOOP1

         OSCF => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)           

         ALLOCATE (OSCF%MEASURE(1:OSCF%NG), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'OSCF%MEASURE', IERR)
         OSCF%MEASURE = 0.0_EB

         ALLOCATE (OSCF%CELLTYPE(1:OSCF%NG), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'OSCF%CELLTYPE', IERR)
         OSCF%CELLTYPE = NSCARC_CELLTYPE_NONE

      ENDDO OTHER_MESH_LOOP1

   ENDDO
   !ENDIF
    
   !!! Then set measures and celltypes on internal cells due to chosen coarsening strategy
   CALL SCARC_SETUP_MEASURES (TYPE_COARSENING, NL)
   CALL SCARC_SETUP_CELLTYPES (TYPE_COARSENING, NL)

   !!! Set dimensions for coarser mesh and define sizes of prolongation and restriction matrices
   CALL SCARC_SETUP_SIZES (NSCARC_SIZE_TRANSFERC, NL)

   !!! Print latex information if requested (only temporarily for debugging purposes)
!   IF (TYPE_LATEX == NSCARC_LATEX_ALL) THEN
      CALL SCARC_LATEX_GRID(NSCARC_LATEX_STAGGERED,NL)
      CALL SCARC_LATEX_GRID(NSCARC_LATEX_EQUAL,NL)
      CALL SCARC_LATEX_GRID(NSCARC_LATEX_NUMBER,NL)
!   ENDIF

   CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_CELLTYPE,  NL)
   CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPEE')

   !!!-------------------------------------------------------------------------------------------------
   !!! Allocate and define grid transfer matrices
   !!!  NCE  : number of extended cells in find grid 
   !!!  NCCE : number of extended cells in coarse grid 
   !!!  NCW  : number of wall cells in coarse grid
   !!!-------------------------------------------------------------------------------------------------
   DO NM = NMESHES_MIN, NMESHES_MAX

      SCF => SCARC(NM)%COMPACT(NL)            

      !!! ---------------- allocate prolongation matrix including row and column pointers
      ALLOCATE (SCF%P(SCF%NPE+10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'P', IERR)
      SCF%P = 0.0_EB
   
      ALLOCATE (SCF%P_COL(SCF%NPE+10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'P_COL', IERR)
      SCF%P_COL = 0.0_EB
   
      ALLOCATE (SCF%P_ROW(SCF%NCE+10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'P_ROW', IERR)
      SCF%P_ROW = 0.0_EB
   

      !!! ---------------- allocate restriction matrix including row and column pointers
      ALLOCATE (SCF%R(SCF%NRE+10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'R', IERR)
      SCF%R = 0.0_EB
   
      ALLOCATE (SCF%R_COL(SCF%NRE+10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'R_COL', IERR)
      SCF%R_COL = 0.0_EB

      ALLOCATE (SCF%R_ROW(SCF%NCCE+10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'R_ROW', IERR)
      SCF%R_ROW = 0.0_EB


      OTHER_MESH_LOOP2: DO NOM = 1, NMESHES

         IF (NOM == NM) CYCLE OTHER_MESH_LOOP2
         OSF  => SCARC(NM)%OSCARC(NOM)      
         IF (OSF%NICMAX_S==0 .AND. OSF%NICMAX_R==0) CYCLE OTHER_MESH_LOOP2
         OSCF  => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)      

         ALLOCATE (OSCF%P(OSCF%NP+10), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'P', IERR)
         OSCF%P = 0.0_EB
   
         ALLOCATE (OSCF%P_COL(OSCF%NP+10), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'P_COL', IERR)
         OSCF%P_COL = 0.0_EB
   
         ALLOCATE (OSCF%P_ROW(OSCF%NC+10), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'P_ROW', IERR)
         OSCF%P_ROW = 0.0_EB
   
         ALLOCATE (OSCF%R(OSCF%NP+10), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'R', IERR)
         OSCF%P = 0.0_EB
   
         ALLOCATE (OSCF%R_COL(OSCF%NP+10), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'R_COL', IERR)
         OSCF%P_COL = 0.0_EB
   
         ALLOCATE (OSCF%R_ROW(OSCF%NC+10), STAT=IERR)
         CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'R_ROW', IERR)
         OSCF%P_ROW = 0.0_EB
   
      ENDDO OTHER_MESH_LOOP2
   ENDDO

   !!! determine prolongation and restriction matrix for the corresponding level
   CALL SCARC_SETUP_PROLONGATION(NL)

   CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_PROLONGATION', 'CELLTYPE AFTER SETUP_PROLONGATION')

   CALL SCARC_SETUP_OVERLAPS (NSCARC_MATRIX_PROLONGATION, NL)

   CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_PROLONGATION', 'CELLTYPE AFTER SETUP_OVERLAPS')
   CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_PROLONGATION, NL, 'SETUP_PROLONGATION', 'FINAL PROLONG2')

   CALL SCARC_LATEX_MATRIX2(SCARC(1)%COMPACT(1)%P, SCARC(1)%COMPACT(1)%P_ROW, SCARC(1)%COMPACT(1)%P_COL, &
                            SCARC(1)%COMPACT(1)%NC, SCARC(1)%COMPACT(1)%NCC, 1, 1, 'P')

   CALL SCARC_SETUP_RESTRICTION(NL)

   !!! print out matrix in debug mode
   IF (TYPE_DEBUG >= NSCARC_DEBUG_MEDIUM .AND. NL>=1) THEN
      !CALL SCARC_LATEX_MATRIX(SCF%P, SCF%P_ROW, SCF%P_COL, SCF%NC, SCF%NCC, NM, NL, 'P')
      !CALL SCARC_LATEX_MATRIX(SCF%R, SCF%R_ROW, SCF%R_COL, SCF%NCC, SCF%NC, NM, NL, 'R')
      SCF => SCARC(1)%COMPACT(1)            
      CALL SCARC_LATEX_MATRIX2(SCF%P, SCF%P_ROW, SCF%P_COL, SCF%NC, SCF%NCC, 1, 1, 'P')
      CALL SCARC_LATEX_MATRIX2(SCF%R, SCF%R_ROW, SCF%R_COL, SCF%NCC, SCF%NC, 1, 1, 'R')
   ENDIF

   !!!-------------------------------------------------------------------------------------------------
   !!! Allocate coarse grid matrix including pointer arrays
   !!! Note: number of cells on coarse level corresponds to number of c-points on fine level
   !!! Compute coarse grid matrix by multiplication with restriction and prolongation matrix:
   !!!  A_coarse := R * A_fine * P
   !!!-------------------------------------------------------------------------------------------------
   DO NM = NMESHES_MIN, NMESHES_MAX

      SCF => SCARC(NM)%COMPACT(NL)                 ! Pointer to fine level
      SCC => SCARC(NM)%COMPACT(NL+1)               ! Pointer to coarse level

      SCC%NC  = SCF%NCC
      SCC%NCE = SCF%NCCE
      SCC%NW  = SCF%NCW
   
      !!! Allocate coarse matrix structures
      ALLOCATE (SCC%A(20*SCF%NCCE*10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'SCC%A', IERR)
      SCC%A = 0.0_EB
   
      ALLOCATE (SCC%A_COL(20*SCF%NCCE*10), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'SCC%A_COL', IERR)
      SCC%A_COL = 0

      ALLOCATE (SCC%A_ROW(SCF%NCCE+1), STAT=IERR)
      CALL CHKMEMERR ('SCARC_SETUP_COARSENING', 'SCC%A_ROW', IERR)
      SCC%A_ROW = 0
   
      !!! Allocate WALL-information for coarser grids (own and neighboring grids)
      ALLOCATE(SCC%GHOST_PTR(SCC%NC+1:SCC%NCE), STAT=IERR)
      CALL ChkMemErr('SCARC_SETUP_COARSENING','GHOST_PTR',IERR)
      SCC%GHOST_PTR = 0
  
      DO IC = SCF%NC+1,SCF%NCE
         ICC = SCF%CELLTYPE(IC)
      ENDDO

      OTHER_MESHES_LOOP: DO NOM = 1, NMESHES

         IF (NOM == NM) CYCLE OTHER_MESHES_LOOP
         OSF  => SCARC(NM)%OSCARC(NOM)      
         IF (OSF%NICMAX_S==0 .AND. OSF%NICMAX_R==0) CYCLE OTHER_MESHES_LOOP
         OSCC => SCARC(NM)%OSCARC(NOM)%COMPACT(NL+1)                     

         ALLOCATE(OSCC%WALL(OSCC%NW), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_EXCHANGE','WALL',IERR)

         ALLOCATE(OSCC%WALL(OSCC%NW), STAT=IERR)
         CALL ChkMemErr('SCARC_SETUP_EXCHANGE','WALL',IERR)

      ENDDO OTHER_MESHES_LOOP

   ENDDO

   CALL SCARC_TRANSFER_MATRIX (NL)
   IF (NMESHES > 1) CALL SCARC_SETUP_WALLINFO_AMG (NL)
   !CALL SCARC_SETUP_SUBDIVISION_AMG (NL)

ENDDO LEVEL_LOOP

!DO NL = NLEVEL_MIN, NLEVEL_MAX
!   DO NM = NMESHES_MIN, NMESHES_MAX
!      SCF => SCARC(NM)%COMPACT(NL)  
!      DEALLOCATE(SCF%MEASURE)
!      DEALLOCATE(SCF%CELLTYPE)
!   ENDDO
!ENDDO

END SUBROUTINE SCARC_SETUP_COARSENING



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Resize an existing array whose final size wasn't clear at the point of first allocation
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!SUBROUTINE RESIZE_ARRAY(A, newSize)
!IMPLICIT NONE
!INTEGER, DIMENSION(:), INTENT(INOUT) :: A
!INTEGER, INTENT(IN) :: newSize
!INTEGER, DIMENSION(:), ALLOCATABLE :: B
!ALLOCATE(B(LBOUND(A):UBOUND(A))
!B = A
!DEALLOCATE(A)
!ALLOCATE(A(newSize))
!A(LBOUND(B):UBOUND(B)) = B
!DEALLOCATE(B)
!END SUBROUTINE RESIZE_ARRAY


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE PRINT_MATRIX(A, A_ROW, A_COL, NC1, NC2, NM, NL, CNAME)
REAL(EB), DIMENSION(:), INTENT(IN) :: A
INTEGER , DIMENSION(:), INTENT(IN) :: A_ROW
INTEGER , DIMENSION(:), INTENT(IN) :: A_COL
INTEGER , INTENT(IN) :: NM, NL, NC1, NC2
CHARACTER(1), INTENT(IN):: CNAME
INTEGER :: IC, JC, ICOL, MMATRIX
CHARACTER(60):: CMATRIX
REAL(EB):: MATRIX_LINE(1000)

WRITE (CMATRIX, '(A,A1,A,i2.2,A,i2.2,A)') 'matrix/',CNAME,'_mesh',NM,'_level',NL,'.txt'
MMATRIX=GET_FILE_NUMBER()
OPEN(MMATRIX,FILE=CMATRIX)
      
DO IC = 1, NC1
   MATRIX_LINE=0.0_EB
   DO JC = 1, NC2
      DO  ICOL= A_ROW(IC), A_ROW(IC+1)-1       
         IF (A_COL(ICOL)==JC) MATRIX_LINE(JC)=A(ICOL)
      ENDDO
   ENDDO
   WRITE(MMATRIX,1000) (MATRIX_LINE(JC),JC=1,NC2)
ENDDO

CLOSE(MMATRIX)

1000 FORMAT(F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',&
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,';')
END SUBROUTINE PRINT_MATRIX

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE PRINT_MATRIX2(A, A_ROW, A_COL, NC1, NC2, NM, NL, CNAME)
REAL(EB), DIMENSION(:), INTENT(IN) :: A
INTEGER , DIMENSION(:), INTENT(IN) :: A_ROW
INTEGER , DIMENSION(:), INTENT(IN) :: A_COL
INTEGER , INTENT(IN) :: NM, NL, NC1, NC2
CHARACTER(1), INTENT(IN):: CNAME
INTEGER :: IC, JC, ICOL, MMATRIX
CHARACTER(60):: CMATRIX
REAL(EB):: MATRIX_LINE(1000)

WRITE (CMATRIX, '(A,A1,A,i2.2,A,i2.2,A)') 'matrix2/',CNAME,'_mesh',NM,'_level',NL,'.txt'
MMATRIX=GET_FILE_NUMBER()
OPEN(MMATRIX,FILE=CMATRIX)
      
DO IC = 1, NC1
   MATRIX_LINE=0.0_EB
   DO JC = 1, NC2
      DO  ICOL= A_ROW(IC), A_ROW(IC+1)-1       
         IF (A_COL(ICOL)==JC) MATRIX_LINE(JC)=A(ICOL)
      ENDDO
   ENDDO
   WRITE(MMATRIX,1000) (MATRIX_LINE(JC),JC=1,NC2)
ENDDO

CLOSE(MMATRIX)

1000 FORMAT(40f8.2)
END SUBROUTINE PRINT_MATRIX2

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Store subdivision information
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_SUBDIVISION_AMG(NL)
INTEGER, INTENT(IN) :: NL
INTEGER :: NM, IW, IOR0, IOR_LAST, NOM, INBR
INTEGER :: NEIGHBORS(20,-3:3)
TYPE (SCARC_COMPACT_TYPE), POINTER :: SCF, SCC

IOR_LAST    = 0
NEIGHBORS   = 0
         
MESHES_LOOP1: DO NM = NMESHES_MIN, NMESHES_MAX
   
   SCF => SCARC(NM)%COMPACT(NL)
   SCC => SCARC(NM)%COMPACT(NL+1)

   SCC%SUBDIVISION = 0

   WALLCELL_LOOP: DO IW = 1, SCC%NW
   
      IOR0 = SCF%WALL(IW)%IOR
      
      IF (IOR_LAST /= IOR0) SCC%SUBDIVISION(1,IOR0) = IW
      SCC%SUBDIVISION(2,IOR0) = SCC%SUBDIVISION(2,IOR0) + 1
      
      NOM= SCF%WALL(IW)%NOM
   
      IF (NOM /= 0) THEN
         NEIGHBOR_LOOP: DO INBR = 1, 20
            IF (NOM == NEIGHBORS(INBR, IOR0)) THEN
               EXIT NEIGHBOR_LOOP
            ELSE IF (NEIGHBORS(INBR, IOR0) /= 0) THEN
               CYCLE NEIGHBOR_LOOP
            ELSE IF (NEIGHBORS(INBR, IOR0) == 0) THEN
               NEIGHBORS(INBR, IOR0) = NOM
               SCC%SUBDIVISION(3,IOR0) = SCC%SUBDIVISION(3,IOR0) + 1
               EXIT NEIGHBOR_LOOP
            ELSE
               WRITE(*,*) 'More than 20 neighbors at one face not allowed yet!'
               STOP
            ENDIF
         ENDDO NEIGHBOR_LOOP
      ENDIF
      
      IOR_LAST = IOR0
   
   ENDDO WALLCELL_LOOP

ENDDO MESHES_LOOP1
         
END SUBROUTINE SCARC_SETUP_SUBDIVISION_AMG



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_WALLINFO_AMG(NL)
INTEGER , INTENT(IN) :: NL
INTEGER :: NM, NOM, ICOL, IW, ICW, NCPL, JC, IERR
TYPE (OSCARC_TYPE), POINTER :: OS
TYPE (SCARC_COMPACT_TYPE) , POINTER :: SCC
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSCC


!!! -----------------------------------------------------------------------------
!!! Loop over all boundary cells IW of fine grid
!!! get corresponding adjacent and ghost cell
!!! -----------------------------------------------------------------------------
MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

   SCC => SCARC(NM)%COMPACT(NL+1)

   DO IW = 1, SCC%NW
   
      NOM = SCC%WALL(IW)%NOM
      OSCC => SCARC(NM)%OSCARC(NOM)%COMPACT(NL+1)
   
      ICW = SCC%WALL(IW)%ICW

      NCPL = 0
      DO ICOL = SCC%A_ROW(ICW)+1, SCC%A_ROW(ICW+1)-1
         JC = SCC%A_COL(ICOL)
         IF (JC > SCC%NC) NCPL = NCPL + 1
      ENDDO

      SCC%WALL(IW)%NCPL = NCPL

      ALLOCATE(SCC%WALL(IW)%ICN(NCPL), STAT=IERR)
      CALL ChkMemErr('SCARC_SETUP_WALLINFO_AMG','ICN',IERR)

      ALLOCATE(SCC%WALL(IW)%ICE(NCPL), STAT=IERR)
      CALL ChkMemErr('SCARC_SETUP_WALLINFO_AMG','ICE',IERR)

      ALLOCATE(SCC%WALL(IW)%ICG(NCPL), STAT=IERR)
      CALL ChkMemErr('SCARC_SETUP_WALLINFO_AMG','ICG',IERR)

      NCPL = 0
      DO ICOL = SCC%A_ROW(ICW)+1, SCC%A_ROW(ICW+1)-1
         JC = SCC%A_COL(ICOL)
         IF (JC > SCC%NC) THEN
            NCPL = NCPL + 1
            SCC%WALL(IW)%ICE(NCPL) = JC
            SCC%WALL(IW)%ICN(NCPL) = SCC%EXT_PTR(JC)
         ENDIF
      ENDDO

    ENDDO

ENDDO MESHES_LOOP

CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_GRID, NL+1)

MESHES_LOOP2: DO NM = NMESHES_MIN, NMESHES_MAX

   OTHER_MESHES_LOOP: DO NOM = 1, NMESHES

      IF (NOM == NM) CYCLE OTHER_MESHES_LOOP
      OS  => SCARC(NM)%OSCARC(NOM)      

      IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE OTHER_MESHES_LOOP
      OSCC  => SCARC(NM)%OSCARC(NOM)%COMPACT(NL+1)      

      ALLOCATE(OSCC%WALL(1:OSCC%NW), STAT=IERR)
      CALL ChkMemErr('SCARC_SETUP_WALLINFO_AMG','OSCC%WALL',IERR)

   ENDDO OTHER_MESHES_LOOP
ENDDO MESHES_LOOP2

CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_WALL, NL+1)

END SUBROUTINE SCARC_SETUP_WALLINFO_AMG


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_LATEX_MATRIX(A, A_ROW, A_COL, NC1, NC2, NM, NL, CNAME)
REAL(EB), DIMENSION(:), INTENT(IN) :: A
INTEGER , DIMENSION(:), INTENT(IN) :: A_ROW
INTEGER , DIMENSION(:), INTENT(IN) :: A_COL
INTEGER , INTENT(IN) :: NM, NL, NC1, NC2
CHARACTER(1), INTENT(IN):: CNAME
INTEGER :: IC, JC, ICOL, MMATRIX
CHARACTER(60):: CMATRIX
REAL(EB):: MATRIX_LINE(1000)

WRITE (CMATRIX, '(A,A1,A,i2.2,A,i2.2,A)') 'matrix/',CNAME,'_mesh',NM,'_level',NL,'.txt'
MMATRIX=GET_FILE_NUMBER()
OPEN(MMATRIX,FILE=CMATRIX)
      
DO IC = 1, NC1
   MATRIX_LINE=0.0_EB
   DO JC = 1, NC2
      DO  ICOL= A_ROW(IC), A_ROW(IC+1)-1       
         IF (A_COL(ICOL)==JC) MATRIX_LINE(JC)=A(ICOL)
      ENDDO
   ENDDO
   WRITE(MMATRIX,1000) (MATRIX_LINE(JC),JC=1,NC2)
ENDDO

CLOSE(MMATRIX)

1000 FORMAT(F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',&
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',', &
            F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,',',F11.6,';')
END SUBROUTINE SCARC_LATEX_MATRIX

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_LATEX_MATRIX2(A, A_ROW, A_COL, NC1, NC2, NM, NL, CNAME)
REAL(EB), DIMENSION(:), INTENT(IN) :: A
INTEGER , DIMENSION(:), INTENT(IN) :: A_ROW
INTEGER , DIMENSION(:), INTENT(IN) :: A_COL
INTEGER , INTENT(IN) :: NM, NL, NC1, NC2
CHARACTER(1), INTENT(IN):: CNAME
INTEGER :: IC, JC, ICOL, MMATRIX
CHARACTER(60):: CMATRIX
REAL(EB):: MATRIX_LINE(1000)

WRITE (CMATRIX, '(A,A1,A,i2.2,A,i2.2,A)') 'matrix2/',CNAME,'_mesh',NM,'_level',NL,'.txt'
MMATRIX=GET_FILE_NUMBER()
OPEN(MMATRIX,FILE=CMATRIX)
      
DO IC = 1, NC1
   MATRIX_LINE=0.0_EB
   DO JC = 1, NC2
      DO  ICOL= A_ROW(IC), A_ROW(IC+1)-1       
         IF (A_COL(ICOL)==JC) MATRIX_LINE(JC)=A(ICOL)
      ENDDO
   ENDDO
   WRITE(MMATRIX,1000) (MATRIX_LINE(JC),JC=1,NC2)
ENDDO

CLOSE(MMATRIX)

1000 FORMAT(40f8.2)
END SUBROUTINE SCARC_LATEX_MATRIX2


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_LATEX_WALL(MTABLE, NM, NL)
INTEGER, INTENT(IN):: NM, NL, MTABLE
INTEGER :: IW, ICPL, NCPL, NOM, NOM0, ICE
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

SC => SCARC(NM)%COMPACT(NL)

!WRITE (CTABLE, '(A,A,A,i2.2,A,i2.2,A)') 'tables/',CNAME,'_mesh',NM,'_level',NL,'.tex'
!MTABLE=GET_FILE_NUMBER()
!OPEN(MTABLE,FILE=CTABLE)

WRITE(MTABLE,100) NM
WRITE(MTABLE,500) NM
WRITE(MTABLE,1000)
WRITE(MTABLE,1001) NM
WRITE(MTABLE,2000)
!WRITE(MTABLE,2001) 'IW','IC\_WALL','IC\_EXT','IC\_GHOST','IC\_GHOST'
WRITE(MTABLE,2001) 'IW','ICW','ICE','ICG','ICN'
NOM0 = 0
DO IW = 1, SC%NW
   NCPL = SC%WALL(IW)%NCPL
   NOM = SC%WALL(IW)%NOM
   IF (NOM == 0) CYCLE
   IF (NOM /= NOM0) WRITE(MTABLE,2000)
   SELECT CASE(NCPL)
      CASE (1)
         WRITE(MTABLE,3001) IW, SC%WALL(IW)%ICW,&
                            (SC%WALL(IW)%ICE(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICG(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICN(ICPL), ICPL=1,NCPL)
      CASE (2)
         WRITE(MTABLE,3002) IW, SC%WALL(IW)%ICW,&
                            (SC%WALL(IW)%ICE(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICG(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICN(ICPL), ICPL=1,NCPL)
      CASE (3)
         WRITE(MTABLE,3003) IW, SC%WALL(IW)%ICW,&
                            (SC%WALL(IW)%ICE(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICG(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICN(ICPL), ICPL=1,NCPL)
      CASE (4)
         WRITE(MTABLE,3004) IW, SC%WALL(IW)%ICW,&
                            (SC%WALL(IW)%ICE(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICG(ICPL), ICPL=1,NCPL), &
                            (SC%WALL(IW)%ICN(ICPL), ICPL=1,NCPL)
   END SELECT
   !WRITE(MTABLE,2000)
   NOM0 = NOM
ENDDO
WRITE(MTABLE,2000)
WRITE(MTABLE,4000)
WRITE(MTABLE,5000)


!!! WALL_PTR
WRITE(MTABLE,500) NM
WRITE(MTABLE,1004)
WRITE(MTABLE,1002) NM
WRITE(MTABLE,2000)
WRITE(MTABLE,2002) 'ICE', 'IW'
WRITE(MTABLE,2000)
DO ICE = SC%NC+1, SC%NCE
   WRITE(MTABLE,3000) ICE, SC%WALL_PTR(ICE)
   !WRITE(MTABLE,2000)
ENDDO
WRITE(MTABLE,2000)
WRITE(MTABLE,4000)
WRITE(MTABLE,5000)

100  FORMAT( /,'\vspace{1cm}',/,'{\bf MESH ',i3,'} \\',/)
500  FORMAT( '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%',/, &
             '%%%    Mesh(',i2,')',/,&
             '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
1000 FORMAT( '\begin{minipage}{8cm}')
1004 FORMAT( '\begin{minipage}{5cm}')
1001 FORMAT( '\flushleft{\bf {\footnotesize Mesh(',i3,'):WALL:}}\\[2ex]',/,&
             '\begin{tabular}{|c|c|c|c|c|}')
1002 FORMAT( '\flushleft{\bf {\footnotesize Mesh(',i3,'):WALL\_PTR:}}\\[2ex]',/,&
             '\begin{tabular}{|c|c|}')
2000 FORMAT( '\hline')
2001 FORMAT ('{\footnotesize ',a,'} & {\footnotesize ',a,'} & {\footnotesize ',a,'} & {\footnotesize ',a,&
             '} & {\footnotesize ',a,'} \\')
2002 FORMAT ('{\footnotesize ',a,'} & {\footnotesize ',a,'} \\')
3000 FORMAT (i4,' &',i4, '\\')
3001 FORMAT (i4,' &',i4, ' &',i4,' &',i4,' &',i4,'\\')
3002 FORMAT (i4,' &',i4, ' &',i4,',',i4,' &',i4,',',i4,' &',i4,',',i4,'\\')
3003 FORMAT (i4,' &',i4, ' &',i4,',',i4,',',i4,' &',i4,',',i4,',',i4,' &',i4,',',i4,',',i4,'\\')
3004 FORMAT (i4,' &',i4, ' &',i4,',',i4,',',i4,',',i4,' &',i4,',',i4,',',i4,',',i4,' &',i4,',',i4,',',i4,',',i4,'\\')
4000 FORMAT( '\end{tabular}')
5000 FORMAT( '\end{minipage}',/,'\vspace{0.5cm}')
END SUBROUTINE SCARC_LATEX_WALL


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_LATEX_NOM(MTABLE, NM, NOM, NL)
INTEGER, INTENT(IN):: NM, NOM, NL, MTABLE
INTEGER :: IG
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSC

OSC => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)

!WRITE (CTABLE, '(A,A,A,i2.2,A,I2.2,A,i2.2,A)') 'tables/',CNAME,'_mesh',NM,'_nom',nom,'_level',NL,'.tex'
!MTABLE=GET_FILE_NUMBER()
!OPEN(MTABLE,FILE=CTABLE)

!WRITE(MTABLE,100) NM, NOM

!!! NOM: WALL_PTR
WRITE(MTABLE, 500) NM,':WALL\_PTR(',NOM,'), GHOST\_PTR(',NOM,'), NOM\_PTR(',NOM,')'
WRITE(MTABLE,1000)
WRITE(MTABLE,1500) NM,NOM
WRITE(MTABLE,2000)
WRITE(MTABLE,3000) 'IG', 'IW','ICE','IW'
WRITE(MTABLE,2000)
DO IG = 1, OSC%NG
   WRITE(MTABLE,3001) IG, OSC%WALL_PTR(IG), OSC%GHOST_PTR(IG), OSC%NOM_PTR(IG)
   !WRITE(MTABLE,2000)
ENDDO
WRITE(MTABLE,2000)
WRITE(MTABLE,4000)
WRITE(MTABLE,5000)



100  FORMAT( /,'\vspace{5mm}',/,'{\bf MESH',i3,': NOM ',i3,' }\\', /)
500  FORMAT( '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%',/, &
             '%%%    ', i3, a,i3,a,i3,a,i3,a/,&
             '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
1000 FORMAT( '\begin{minipage}{4cm}')
1500 FORMAT( '\flushleft{\bf {\footnotesize Mesh ',i3,' : NOM',i3,':}}\\[2ex]',/,&
             '\begin{tabular}{|c|c|c|c|}')
2000 FORMAT( '\hline')
3000 FORMAT ('{\footnotesize ',a,'} & {\footnotesize ',a, '} & {\footnotesize ',a, '} & {\footnotesize ',a,'} \\')
3001 FORMAT (i4,' &',i4, ' &',i4,' &',i4,'\\')
4000 FORMAT( '\end{tabular}')
5000 FORMAT( '\end{minipage}')
END SUBROUTINE SCARC_LATEX_NOM



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if a cell IC is strongly coupled to another cell JC
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
LOGICAL FUNCTION STRONGLY_COUPLED(A, A_ROW, IC, ICOL)
REAL(EB), DIMENSION(:), INTENT(IN) :: A
INTEGER , DIMENSION(:), INTENT(IN) :: A_ROW
INTEGER , INTENT(IN) :: IC, ICOL
INTEGER :: JCOL
REAL(EB) :: AMG_TOL, VAL_MAX

AMG_TOL = 0.25_EB
VAL_MAX = 0.00_EB

DO  JCOL= A_ROW(IC)+1, A_ROW(IC+1)-1       
   IF (JCOL /= ICOL) VAL_MAX = MAX(VAL_MAX, A(JCOL))
ENDDO

IF (A(ICOL) >= AMG_TOL * VAL_MAX) THEN
   STRONGLY_COUPLED=.TRUE.
ELSE
   STRONGLY_COUPLED=.FALSE.
ENDIF
RETURN

END FUNCTION STRONGLY_COUPLED


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine measure of cells corresponding to requested coarsening type
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_MEASURES(NTYPE, NL)
INTEGER, PARAMETER  :: NCOUPLINGS = 20
INTEGER, INTENT(IN) :: NTYPE, NL
INTEGER  :: NM, IC, JC, ICOL, IW
INTEGER  :: IX, IY, IZ
REAL(EB) :: RAND_NUM, RAND_NUM2
LOGICAL  :: BXFIRST, BZFIRST
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC, SCC


!!! Select coarsening strategy
SELECT CASE (NTYPE)

   !!!-------------------------------------------------------------------------------------------------
   !!! first set measures on internal boundary layers (adjacent to neighboring meshes)
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_BDRY)

      BDRY_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

         SC => SCARC(NM)%COMPACT(NL)

         BDRY_MEASURE_LOOP: DO IW = 1, SC%NW
            IF (SC%WALL(IW)%NOM == 0) CYCLE BDRY_MEASURE_LOOP
            IC = SC%WALL(IW)%ICW
            SC%MEASURE(IC)=NSCARC_MEASURE_BDRY
         ENDDO BDRY_MEASURE_LOOP

      ENDDO BDRY_LOOP

   !!!-------------------------------------------------------------------------------------------------
   !!! RS3-coarsening: 
   !!!      - Original Ruge-Stuben method with parallel postprocessing
   !!!      - Produces good C/F splittings but is inherently serial.  
   !!!      - May produce AMG hierarchies with relatively high operator complexities.
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_RS3)

      RS3_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SC => SCARC(NM)%COMPACT(NL)            
      
         SC%MEASURE = NSCARC_MEASURE_NONE
         RS3_MEASURE_LOOP: DO IC = 1, SC%NC
            DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
               IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) SC%MEASURE(IC) = SC%MEASURE(IC) + 1.0_EB
            ENDDO
         ENDDO RS3_MEASURE_LOOP

      
         !!! set measures on boundary layer to zero and decrease probability of a neighboring cell to be a coarse cell
         RS3_MEASURE_BDRY_LOOP: DO IW = 1, SC%NW
            IF (SC%WALL(IW)%NOM == 0) CYCLE RS3_MEASURE_BDRY_LOOP
            IC = SC%WALL(IW)%ICW
            IF (SC%CELLTYPE(IC) == NSCARC_CELLTYPE_COARSE) THEN              ! check here 
               DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                  JC = SC%A_COL(ICOL)
                  IF (JC<=SC%NC.AND.STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) THEN
                     IF (SC%INTERNAL_BDRY_CELL(JC)/=0) THEN
                        SC%MEASURE(JC) = SC%MEASURE(JC) - 1.0_EB
                     ENDIF
                  ENDIF
               ENDDO
            ENDIF
            SC%MEASURE(IC) = NSCARC_MEASURE_NONE
         ENDDO RS3_MEASURE_BDRY_LOOP
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE, NL, 'SETUP_MEASURES', 'MEASURE AFTER BDRY  RS3 ')
      ENDDO RS3_LOOP


   !!!-------------------------------------------------------------------------------------------------
   !!! FDSA2-coarsening:
   !!!     -  path l=2, length l=2  ==> S_i^(2,2) with parallel postprocessing
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_FDSA2)

      FDSA2_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

         SC  => SCARC(NM)%COMPACT(NL)
         SCC => SCARC(NM)%COMPACT(NL+1)

         IF (NMESHES >= 1) THEN

            !!! Set internal measures corresponding to A2-coarsening
            SELECT CASE (TYPE_DIMENSION)
   
               !!! -------------------------------- 2D ------------------------------------------------
               CASE (NSCARC_DIMENSION_TWO)
 
                  SCC%NX=0
                  SCC%NY=1
                  SCC%NZ=0
                  BZFIRST=.TRUE.
                  DO IZ = 1, SC%NZ
                     BXFIRST=.TRUE.
                     DO IX = 1, SC%NX
                        IC = (IZ-1)*SC%NX + IX
                        IF (MOD(IX,2)==1.AND.MOD(IZ,2)==1) THEN
                           SC%MEASURE(IC) = 6.0_EB
                           IF (BZFIRST) SCC%NX=SCC%NX+1
                           IF (BXFIRST) SCC%NZ=SCC%NZ+1
                        ELSE IF (MOD(IX,2)==0.AND.MOD(IZ,2)==0) THEN
                           SC%MEASURE(IC) = 4.0_EB
                        ELSE
                           SC%MEASURE(IC) = 5.0_EB
                        ENDIF
                        BXFIRST=.FALSE.
                     ENDDO
                     BZFIRST=.FALSE.
                  ENDDO
   
               !!! -------------------------------- 3D ------------------------------------------------
               CASE (NSCARC_DIMENSION_THREE)
                  DO IZ = 1, SC%NZ
                     DO IY = 1, SC%NY
                        DO IX = 1, SC%NX
                           IC = (IZ-1)*SC%NX*SC%NY + (IY-1)*SC%NX + IX
                           IF (MOD(IZ,2)==1) THEN
                              IF (MOD(IX,2)==1.AND.MOD(IY,2)==1) THEN
                                 SC%MEASURE(IC) = 6.0_EB
                              ELSE
                                 SC%MEASURE(IC) = 5.0_EB
                              ENDIF
                           ELSE
                              IF (MOD(IX,2)==0.AND.MOD(IY,2)==0) THEN
                                 SC%MEASURE(IC) = 6.0_EB
                              ELSE
                                 SC%MEASURE(IC) = 5.0_EB
                              ENDIF
                           ENDIF
                        ENDDO
                     ENDDO
                  ENDDO
            END SELECT
   
         ELSE

            !!! First Initialize internal cells to be weakly coupled fine cells
            !!! Then set internal measures corresponding to A2-coarsening
            SELECT CASE (TYPE_DIMENSION)
   
               !!! -------------------------------- 2D ------------------------------------------------
               CASE (NSCARC_DIMENSION_TWO)
                  DO IZ = 2, SC%NZ-1
                     DO IX = 2, SC%NX-1
                        IC = (IZ-1)*SC%NX + IX
                        CALL RANDOM_NUMBER(RAND_NUM)
                        SC%MEASURE(IC) = 4.0_EB + REAL(INT(RAND_NUM*8.5_EB),EB)/10.0_EB + 0.1_EB
                        SC%MEASURE(IC) = 5.0_EB + RAND_NUM
                     ENDDO
                  ENDDO
                  DO IZ = 3, SC%NZ-2, 2
                     DO IX = 3, SC%NX-2, 2
                        IC = (IZ-1)*SC%NX + IX
                        SC%MEASURE(IC)=7.0_EB
                        DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                           JC = SC%A_COL(ICOL)
                           IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) SC%MEASURE(JC) = 6.0_EB
                        ENDDO
                     ENDDO
                  ENDDO
   
               !!! -------------------------------- 3D ------------------------------------------------
               CASE (NSCARC_DIMENSION_THREE)
                  DO IZ = 2, SC%NZ-1
                     DO IY = 2, SC%NY-1
                        DO IX = 2, SC%NX-1
                           IC = (IZ-1)*SC%NX*SC%NY + (IY-1)*SC%NX + IX
                           CALL RANDOM_NUMBER(RAND_NUM)
                           SC%MEASURE(IC) = 4.0_EB + REAL(INT(RAND_NUM*8.5_EB),EB)/10.1_EB + 0.1_EB
                           SC%MEASURE(IC) = 4.0_EB + RAND_NUM
                        ENDDO
                     ENDDO
                  ENDDO
                  DO IZ = 3, SC%NZ-2, 2
                     DO IY = 3, SC%NY-2, 2
                        DO IX = 3, SC%NX-2, 2
                           IC = (IZ-1)*SC%NX*SC%NY + (IY-1)*SC%NX + IX
                           SC%MEASURE(IC)=6.0_EB
                           DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                              JC = SC%A_COL(ICOL)
                              IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) SC%MEASURE(JC) = 5.0_EB
                           ENDDO
                        ENDDO
                     ENDDO
                  ENDDO

            END SELECT

         ENDIF

CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE, NL, 'SETUP_MEASURES', 'A: MEASURE IN LOOP ')
      ENDDO FDSA2_LOOP

      IF (NMESHES > 1) THEN

         FDSA2_LOOP3: DO NM = NMESHES_MIN, NMESHES_MAX

            SC => SCARC(NM)%COMPACT(NL)            

            FDSA2_MEASURE_LOOP3: DO IW = 1, SC%NW
               IF (SC%WALL(IW)%NOM == 0) CYCLE FDSA2_MEASURE_LOOP3
               IC = SC%WALL(IW)%ICW        
               SC%MEASURE(IC)=0.0_EB
               DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                  JC = SC%A_COL(ICOL)
                  IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL).AND.SC%MEASURE(JC)/=NSCARC_MEASURE_COARSE) THEN
                     SC%MEASURE(IC) = SC%MEASURE(IC) + 1.0_EB
                     !SC%MEASURE(IC) = 0.0_EB
                  ENDIF
               ENDDO
               CALL RANDOM_NUMBER(RAND_NUM)
               CALL RANDOM_NUMBER(RAND_NUM2)
               RAND_NUM = 0.89_EB* RAND_NUM + 0.089_EB * RAND_NUM2
               SC%MEASURE(IC) = SC%MEASURE(IC) + RAND_NUM
           
            ENDDO FDSA2_MEASURE_LOOP3

CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE, NL, 'SETUP_MEASURES', 'B: MEASURE IN LOOP ')
   
         ENDDO FDSA2_LOOP3
   
      ENDIF



   !!!-------------------------------------------------------------------------------------------------
   !!! PMIS: Parallel Modified Independent Set 
   !!!     - Very fast construction with low operator complexity.  
   !!!     - Convergence can deteriorate with increasing problem size on structured meshes.  
   !!!     - Uses method similar to Luby's Maximal Independent Set algorithm.
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_PMIS, NSCARC_COARSENING_PMISG)

      PMIS_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

         SC => SCARC(NM)%COMPACT(NL)

         !!! First determine the measure of each cell and add a random number between (0,1)
         PMIS_MEASURE_LOOP: DO IC = 1, SC%NC

            DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
               IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) SC%MEASURE(IC) = SC%MEASURE(IC) + 1.0_EB
            ENDDO

            CALL RANDOM_NUMBER(RAND_NUM)
            CALL RANDOM_NUMBER(RAND_NUM2)
            RAND_NUM = 0.05_EB + 0.9_EB* RAND_NUM + 0.09_EB * RAND_NUM2
            SC%MEASURE(IC) = SC%MEASURE(IC) + RAND_NUM

         ENDDO PMIS_MEASURE_LOOP

      ENDDO PMIS_LOOP

IF (NMESHES == 1) THEN


SCARC(1)%COMPACT(1)%MEASURE(64)=2.67 
SCARC(1)%COMPACT(1)%MEASURE(65)=3.78  
SCARC(1)%COMPACT(1)%MEASURE(66)=4.01  
SCARC(1)%COMPACT(1)%MEASURE(67)=3.84  
SCARC(1)%COMPACT(1)%MEASURE(68)=3.66  
SCARC(1)%COMPACT(1)%MEASURE(69)=3.32  
SCARC(1)%COMPACT(1)%MEASURE(70)=3.66  
SCARC(1)%COMPACT(1)%MEASURE(71)=3.91  
SCARC(1)%COMPACT(1)%MEASURE(72)=3.00

SCARC(1)%COMPACT(1)%MEASURE(55)=3.61  
SCARC(1)%COMPACT(1)%MEASURE(56)=4.93  
SCARC(1)%COMPACT(1)%MEASURE(57)=4.58  
SCARC(1)%COMPACT(1)%MEASURE(58)=4.43  
SCARC(1)%COMPACT(1)%MEASURE(59)=4.28  
SCARC(1)%COMPACT(1)%MEASURE(60)=4.31  
SCARC(1)%COMPACT(1)%MEASURE(61)=4.40  
SCARC(1)%COMPACT(1)%MEASURE(62)=4.92  
SCARC(1)%COMPACT(1)%MEASURE(63)=3.28

SCARC(1)%COMPACT(1)%MEASURE(46)=3.75  
SCARC(1)%COMPACT(1)%MEASURE(47)=4.34  
SCARC(1)%COMPACT(1)%MEASURE(48)=4.72  
SCARC(1)%COMPACT(1)%MEASURE(49)=4.97  
SCARC(1)%COMPACT(1)%MEASURE(50)=4.47  
SCARC(1)%COMPACT(1)%MEASURE(51)=4.89  
SCARC(1)%COMPACT(1)%MEASURE(52)=4.52  
SCARC(1)%COMPACT(1)%MEASURE(53)=4.63  
SCARC(1)%COMPACT(1)%MEASURE(54)=3.20

SCARC(1)%COMPACT(1)%MEASURE(37)=3.33  
SCARC(1)%COMPACT(1)%MEASURE(38)=4.82  
SCARC(1)%COMPACT(1)%MEASURE(39)=4.62  
SCARC(1)%COMPACT(1)%MEASURE(40)=4.59  
SCARC(1)%COMPACT(1)%MEASURE(41)=4.43  
SCARC(1)%COMPACT(1)%MEASURE(42)=4.29  
SCARC(1)%COMPACT(1)%MEASURE(43)=4.92  
SCARC(1)%COMPACT(1)%MEASURE(44)=4.71  
SCARC(1)%COMPACT(1)%MEASURE(45)=3.30

SCARC(1)%COMPACT(1)%MEASURE(28)=4.02  
SCARC(1)%COMPACT(1)%MEASURE(29)=4.08  
SCARC(1)%COMPACT(1)%MEASURE(30)=5.01  
SCARC(1)%COMPACT(1)%MEASURE(31)=4.31  
SCARC(1)%COMPACT(1)%MEASURE(32)=4.58  
SCARC(1)%COMPACT(1)%MEASURE(33)=4.31  
SCARC(1)%COMPACT(1)%MEASURE(34)=4.58  
SCARC(1)%COMPACT(1)%MEASURE(35)=4.38  
SCARC(1)%COMPACT(1)%MEASURE(36)=3.66

SCARC(1)%COMPACT(1)%MEASURE(19)=3.09  
SCARC(1)%COMPACT(1)%MEASURE(20)=4.64  
SCARC(1)%COMPACT(1)%MEASURE(21)=4.20  
SCARC(1)%COMPACT(1)%MEASURE(22)=4.19  
SCARC(1)%COMPACT(1)%MEASURE(23)=4.83  
SCARC(1)%COMPACT(1)%MEASURE(24)=4.78  
SCARC(1)%COMPACT(1)%MEASURE(25)=4.68  
SCARC(1)%COMPACT(1)%MEASURE(26)=4.54  
SCARC(1)%COMPACT(1)%MEASURE(27)=3.21


SCARC(1)%COMPACT(1)%MEASURE(10)=3.44  
SCARC(1)%COMPACT(1)%MEASURE(11)=4.21  
SCARC(1)%COMPACT(1)%MEASURE(12)=4.75  
SCARC(1)%COMPACT(1)%MEASURE(13)=4.32  
SCARC(1)%COMPACT(1)%MEASURE(14)=4.88  
SCARC(1)%COMPACT(1)%MEASURE(15)=4.46  
SCARC(1)%COMPACT(1)%MEASURE(16)=4.77  
SCARC(1)%COMPACT(1)%MEASURE(17)=4.72  
SCARC(1)%COMPACT(1)%MEASURE(18)=3.35

SCARC(1)%COMPACT(1)%MEASURE(1)=2.05  
SCARC(1)%COMPACT(1)%MEASURE(2)=3.43  
SCARC(1)%COMPACT(1)%MEASURE(3)=3.99  
SCARC(1)%COMPACT(1)%MEASURE(4)=3.43  
SCARC(1)%COMPACT(1)%MEASURE(5)=3.84  
SCARC(1)%COMPACT(1)%MEASURE(6)=3.81  
SCARC(1)%COMPACT(1)%MEASURE(7)=3.99  
SCARC(1)%COMPACT(1)%MEASURE(8)=3.78  
SCARC(1)%COMPACT(1)%MEASURE(9)=2.76

ENDIF

END SELECT

CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE, NL, 'SETUP_MEASURES', 'MEASURE BEFORE EXCHANGE')
IF (NMESHES > 1) CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MEASURE, NL)
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE, NL, 'SETUP_MEASURES', 'MEASURE AFTER  EXCHANGE')

END SUBROUTINE SCARC_SETUP_MEASURES


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Setup celltypes of mesh corresponding to requested coarsening strategy
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_CELLTYPES(NTYPE, NL)
INTEGER, PARAMETER  :: NCOUPLINGS = 20, NCYC_MAX=1000
INTEGER, INTENT(IN) :: NTYPE, NL
INTEGER  :: NM
INTEGER  :: IC, JC, KC, ICOL, JCOL, ICYC, ICG
INTEGER  :: IW
REAL(EB) :: MEASURE_MAX, MEASURE_LOCAL_MAX, MEASURE_GLOBAL_MAX, EPS
LOGICAL  :: BIGGEST
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

EPS = 1.0E-12
MEASURE_MAX = 0.0_EB

!!! Define celltypes for corresponding coarsening strategy
SELECT CASE (NTYPE)

   !!!-------------------------------------------------------------------------------------------------
   !!! first set celltypes for cells in internal boundary layers (adjacent to neighboring meshes)
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_BDRY)

      BDRY_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SC => SCARC(NM)%COMPACT(NL)
      
         !!! First define coarse cells on boundary layer(adjacent to neighboring meshes)
         BDRY_CYCLE_LOOP: DO
         
            !!!
            !!! get maximum (remaining) measure for all cells
            !!!
            MEASURE_MAX = 0.0_EB
            BDRY_LOOP1: DO IW = 1, SC%NW
               IF (SC%WALL(IW)%NOM == 0) CYCLE BDRY_LOOP1
               IC = SC%WALL(IW)%ICW
               MEASURE_MAX = MAX(MEASURE_MAX, SC%MEASURE(IC)) 
            ENDDO BDRY_LOOP1
            IF (MEASURE_MAX <= EPS) EXIT BDRY_CYCLE_LOOP
         
            BDRY_LOOP2: DO IW = 1, SC%NW
         
               IF (SC%WALL(IW)%NOM == 0) CYCLE BDRY_LOOP2
               IC = SC%WALL(IW)%ICW

               !!! Take first cell with maximum measure as next coarse cell
               IF (MATCH(MEASURE_MAX, SC%MEASURE(IC))) THEN
         
                  SC%MEASURE(IC)  = 0.0_EB
                  SC%CELLTYPE(IC) = NSCARC_CELLTYPE_COARSE
         
                  !!! Determine set of fine cells 
                  DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
         
                     !!! JC is set to be a fine cell which is no longer measured
                     JC = SC%A_COL(ICOL)
         
                     SC%MEASURE(JC)  = 0.0_EB
                     SC%CELLTYPE(JC) = NSCARC_CELLTYPE_SFINE
         
                     !!!  increase measures of cells KC adjacent to fine cells JC based on strong couplings
                     DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                        KC = SC%A_COL(JCOL)
                        IF (KC > 0 .AND. KC /= IC .AND. (SC%CELLTYPE(KC)==NSCARC_CELLTYPE_NONE)) THEN
                           SC%MEASURE(KC) = SC%MEASURE(KC) + 1.0_EB
                           MEASURE_MAX = MAX(MEASURE_MAX, SC%MEASURE(KC))
                        ENDIF
                     ENDDO 
         
                  ENDDO 
         
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE, NL, 'SETUP_MEASURES', 'BDRY_LOOP2 ')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPE', 'BDRY_LOOP2 ')
                  EXIT BDRY_LOOP2
               ENDIF
         
            ENDDO BDRY_LOOP2
         ENDDO BDRY_CYCLE_LOOP
      ENDDO BDRY_LOOP

      
   !!!-------------------------------------------------------------------------------------------------
   !!! RS3-coarsening
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_RS3)

      RS3_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SC => SCARC(NM)%COMPACT(NL)
      
         RS3_CYCLE_LOOP: DO
         
            !!! get maximum (remaining) measure for all cells
            MEASURE_MAX = MAXVAL(SC%MEASURE(1:SC%NC))
            IF (MEASURE_MAX <= EPS) EXIT RS3_CYCLE_LOOP
         
            RS3_CELL_LOOP: DO IC = 1, SC%NC
         
               !!! Take first cell with maximum measure as next coarse cell
               IF (MATCH(MEASURE_MAX, SC%MEASURE(IC))) THEN
         
                  SC%MEASURE(IC)  = 0.0_EB
                  SC%CELLTYPE(IC) = NSCARC_CELLTYPE_COARSE
         
                  !!! Determine set of fine cells 
                  DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1

                     IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) THEN

                        !!! JC is set to be a fine cell which is no longer measured
                        JC = SC%A_COL(ICOL)
                        SC%MEASURE(JC)  = 0.0_EB
                        IF (SC%CELLTYPE(JC) == NSCARC_CELLTYPE_NONE) SC%CELLTYPE(JC) = NSCARC_CELLTYPE_FINE
         
                        !!!  increase measures of cells KC adjacent to fine cells JC based on strong couplings
                        DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                           IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, JC, JCOL)) THEN
                              KC = SC%A_COL(JCOL)
                              IF (KC /= 0) THEN
                                 IF (KC /= IC .AND. (SC%CELLTYPE(KC)==NSCARC_CELLTYPE_NONE)) THEN
                                    SC%MEASURE(KC) = SC%MEASURE(KC) + 1.0_EB
                                    MEASURE_MAX = MAX(MEASURE_MAX, SC%MEASURE(KC))
                                 ENDIF
                              ENDIF
                           ENDIF
                        ENDDO 
                     ENDIF
                  ENDDO 
                  EXIT RS3_CELL_LOOP
               ENDIF
            ENDDO RS3_CELL_LOOP
         ENDDO RS3_CYCLE_LOOP
         SC%NCW = 0 
      ENDDO RS3_LOOP


   !!!-------------------------------------------------------------------------------------------------
   !!! FDSA2-coarsening
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_FDSA2)

      FDSA2_LOOP1: DO NM = NMESHES_MIN, NMESHES_MAX

         SC => SCARC(NM)%COMPACT(NL)
         FDSA2_CELLTYPE_LOOP: DO IC = 1, SC%NC
            IF (MATCH(NSCARC_MEASURE_COARSE, SC%MEASURE(IC))) THEN
               SC%CELLTYPE(IC) = NSCARC_CELLTYPE_COARSE
               SC%MEASURE(IC)  = NSCARC_MEASURE_NONE
            ELSE IF (MATCH(NSCARC_MEASURE_SFINE, SC%MEASURE(IC))) THEN
               SC%CELLTYPE(IC) = NSCARC_CELLTYPE_SFINE
               SC%MEASURE(IC)  = NSCARC_MEASURE_NONE
            ELSE IF (MATCH(NSCARC_MEASURE_WFINE, SC%MEASURE(IC))) THEN
               SC%CELLTYPE(IC) = NSCARC_CELLTYPE_WFINE
               SC%MEASURE(IC)  = NSCARC_MEASURE_NONE
            ENDIF
         ENDDO FDSA2_CELLTYPE_LOOP

         SC%NCW = 0 

      ENDDO FDSA2_LOOP1

      IF (NMESHES > 1) THEN

         FDSA2_CELLTYPE_LOOP2: DO ICYC = 1, NCYC_MAX
            
            MEASURE_GLOBAL_MAX = 0.0_EB
            FDSA2_LOOP2: DO NM = NMESHES_MIN, NMESHES_MAX
         
               SC => SCARC(NM)%COMPACT(NL)
               MEASURE_LOCAL_MAX  = MAXVAL(SC%MEASURE(1:SC%NC))
               MEASURE_GLOBAL_MAX = MAX(MEASURE_GLOBAL_MAX, MEASURE_LOCAL_MAX)
               IF (MEASURE_LOCAL_MAX <= EPS) CYCLE FDSA2_LOOP2
            
               LOCAL_MAX_LOOP_FDSA2: DO IW = 1, SC%NW
            
                  IF (SC%WALL(IW)%NOM == 0) CYCLE LOCAL_MAX_LOOP_FDSA2

                  IC = SC%WALL(IW)%ICW
                  IF (SC%CELLTYPE(IC) /= NSCARC_CELLTYPE_NONE) CYCLE LOCAL_MAX_LOOP_FDSA2
         
                  !!! compare measure of IC with measures of its strongly coupled neighbors
                  BIGGEST = .TRUE.
                  DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1       
                     JC = SC%A_COL(ICOL)
                     IF (SC%CELLTYPE(JC) == NSCARC_CELLTYPE_COARSE) CYCLE
                     IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) THEN
                        JC = SC%A_COL(ICOL)
                        IF (SC%MEASURE(JC) > SC%MEASURE(IC)) BIGGEST = .FALSE.
                     ENDIF
                  ENDDO 
               
                  !!! if IC has biggest measure set it to be a coarse cell 
                  IF (BIGGEST) THEN
                     SC%CELLTYPE(IC) = NSCARC_CELLTYPE_COARSE
                     DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1       
                        JC = SC%A_COL(ICOL)
                        SC%CELLTYPE(JC) = NSCARC_CELLTYPE_SFINE
                     ENDDO
                     SC%NCW = SC%NCW + 1
                  ENDIF
   
               ENDDO LOCAL_MAX_LOOP_FDSA2
            
               !!! set all cells which are strongly coupled to a coarse cell to be a fine cell
               INDEPENDENT_SET_LOOP_FDSA2: DO IW = 1, SC%NW
                  IF (SC%WALL(IW)%NOM == 0) CYCLE INDEPENDENT_SET_LOOP_FDSA2
                  IC = SC%WALL(IW)%ICW

                  IF (SC%CELLTYPE(IC) == NSCARC_CELLTYPE_COARSE) THEN
                     SC%MEASURE(IC) = 0.0_EB

                     DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
         
                     !!! JC is set to be a fine cell which is no longer measured
                        JC = SC%A_COL(ICOL)
         
                        IF (SC%CELLTYPE(JC) == NSCARC_CELLTYPE_COARSE) THEN
                           WRITE(*,*) 'Wrong coarsening at node ',JC,' on mesh ', NM,' main IC=',IC
                           stop
                        ENDIF

                        SC%MEASURE(JC)  = 0.0_EB
                        SC%CELLTYPE(JC) = NSCARC_CELLTYPE_FINE
         
                     !!!  increase measures of cells KC adjacent to fine cells JC based on strong couplings
                        DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                           KC = SC%A_COL(JCOL)
                           IF (KC /= IC .AND. (SC%CELLTYPE(KC)==NSCARC_CELLTYPE_NONE)) THEN
                              SC%MEASURE(KC) = SC%MEASURE(KC) + 1.0_EB
                              MEASURE_LOCAL_MAX = MAX(MEASURE_LOCAL_MAX, SC%MEASURE(KC))
                           ENDIF
                        ENDDO 
         
                     ENDDO 
                     ENDIF
               ENDDO INDEPENDENT_SET_LOOP_FDSA2
   
            ENDDO FDSA2_LOOP2
   
            IF (MEASURE_GLOBAL_MAX <= EPS) EXIT FDSA2_CELLTYPE_LOOP2

            IF (NMESHES > 1) THEN
               CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MEASURE , NL)
               CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_CELLTYPE, NL)
            ENDIF

            DO NM = NMESHES_MIN, NMESHES_MAX
               SC => SCARC(NM)%COMPACT(NL)
               DO IW = 1, SC%NW
                  IF (SC%WALL(IW)%NOM == 0) CYCLE
                  IC = SC%WALL(IW)%ICW
                  ICG = SC%WALL(IW)%ICG(1)
                  IF (SC%CELLTYPE(ICG) == NSCARC_CELLTYPE_COARSE) THEN
                     SC%MEASURE(IC)  = 0.0_EB
                     SC%CELLTYPE(IC) = NSCARC_CELLTYPE_SFINE
                  ENDIF

               ENDDO
            ENDDO

         ENDDO FDSA2_CELLTYPE_LOOP2
         

      ENDIF
      

   !!!-------------------------------------------------------------------------------------------------
   !!! PMIS-coarsening
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_PMIS)

      
      PMIS_CELLTYPE_LOOP: DO ICYC = 1, NCYC_MAX
         
         MEASURE_GLOBAL_MAX = 0.0_EB
         PMIS_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
            SC => SCARC(NM)%COMPACT(NL)
            MEASURE_LOCAL_MAX  = MAXVAL(SC%MEASURE(1:SC%NC))
            MEASURE_GLOBAL_MAX = MAX(MEASURE_GLOBAL_MAX, MEASURE_LOCAL_MAX)
            IF (MEASURE_LOCAL_MAX <= EPS) CYCLE
         
            LOCAL_MAX_LOOP_PMIS: DO IC = 1, SC%NC
         
               IF (SC%CELLTYPE(IC) /= NSCARC_CELLTYPE_NONE) CYCLE LOCAL_MAX_LOOP_PMIS
      
               !!! compare measure of IC with measures of its strongly coupled neighbors
               BIGGEST = .TRUE.
               DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1       
                  IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) THEN
                     JC = SC%A_COL(ICOL)
                     IF (SC%MEASURE(JC) > SC%MEASURE(IC)) BIGGEST = .FALSE.
                  ENDIF
               ENDDO 
            
               !!! if IC has biggest measure set it to be a coarse cell 
               IF (BIGGEST) SC%CELLTYPE(IC) = NSCARC_CELLTYPE_COARSE

            ENDDO LOCAL_MAX_LOOP_PMIS
         ENDDO PMIS_LOOP
         
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE , NL, 'SETUP_CELLTYPES', 'MEASURE LOOP')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE LOOP')


         IF (NMESHES > 1) CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_CELLTYPE, NL)

         PMIS_LOOP2: DO NM = NMESHES_MIN, NMESHES_MAX

            SC => SCARC(NM)%COMPACT(NL)
            !!! set all cells which are strongly coupled to a coarse cell to be a fine cell
            INDEPENDENT_SET_LOOP_PMIS: DO IC = 1, SC%NCE
               IF (SC%CELLTYPE(IC) == NSCARC_CELLTYPE_COARSE) THEN
                  SC%MEASURE(IC) = 0.0_EB
                  DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1       
                     JC = SC%A_COL(ICOL)
                     IF (JC < 0) CYCLE
                     IF (SC%CELLTYPE(JC) == NSCARC_CELLTYPE_NONE) THEN
                        SC%CELLTYPE(JC) = NSCARC_CELLTYPE_SFINE
                        SC%MEASURE(JC) = 0.0_EB
                     ENDIF
                  ENDDO 
               ENDIF
            ENDDO INDEPENDENT_SET_LOOP_PMIS
         ENDDO PMIS_LOOP2

CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE , NL, 'SETUP_CELLTYPES', 'MEASURE BEFORE EXCH')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE BEFORE EXCH')
         IF (NMESHES > 1)  THEN
            CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MEASURE , NL)
            CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_CELLTYPE, NL)
         ENDIF

         IF (MEASURE_GLOBAL_MAX <= EPS) EXIT PMIS_CELLTYPE_LOOP
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE , NL, 'SETUP_CELLTYPES', 'MEASURE AFTER EXCH')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE AFTER EXCH')

      ENDDO PMIS_CELLTYPE_LOOP
         
      
   !!!-------------------------------------------------------------------------------------------------
   !!! PMISG-coarsening
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_COARSENING_PMISG)

      
      PMISG_CELLTYPE_LOOP: DO ICYC = 1, NCYC_MAX
         
         MEASURE_GLOBAL_MAX = 0.0_EB
         PMISG_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
      
            SC => SCARC(NM)%COMPACT(NL)
            MEASURE_LOCAL_MAX  = MAXVAL(SC%MEASURE(1:SC%NC))
            MEASURE_GLOBAL_MAX = MAX(MEASURE_GLOBAL_MAX, MEASURE_LOCAL_MAX)
            IF (MEASURE_LOCAL_MAX <= EPS) CYCLE
         
            LOCAL_MAX_LOOP_PMISG: DO IC = 1, SC%NC
         
               IF (SC%CELLTYPE(IC) /= NSCARC_CELLTYPE_NONE) CYCLE LOCAL_MAX_LOOP_PMISG
      
               !!! compare measure of IC with measures of its strongly coupled neighbors
               BIGGEST = .TRUE.
               DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1       
                  IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, IC, ICOL)) THEN
                     JC = SC%A_COL(ICOL)
                     IF (SC%MEASURE(JC) > SC%MEASURE(IC)) BIGGEST = .FALSE.
                  ENDIF
               ENDDO 
            
               !!! if IC has biggest measure set it to be a coarse cell 
               IF (BIGGEST) SC%CELLTYPE(IC) = NSCARC_CELLTYPE_COARSE

            ENDDO LOCAL_MAX_LOOP_PMISG
         ENDDO PMISG_LOOP
         
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE , NL, 'SETUP_CELLTYPES', 'MEASURE LOOP')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE LOOP')


         IF (NMESHES > 1) CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_CELLTYPE, NL)

         PMISG_LOOP2: DO NM = NMESHES_MIN, NMESHES_MAX

            SC => SCARC(NM)%COMPACT(NL)
            !!! set all cells which are strongly coupled to a coarse cell to be a fine cell
            INDEPENDENT_SET_LOOP_PMISG: DO IC = 1, SC%NCE
               IF (SC%CELLTYPE(IC) == NSCARC_CELLTYPE_COARSE) THEN
                  SC%MEASURE(IC) = 0.0_EB
                  DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1       
                     JC = SC%A_COL(ICOL)
                     IF (JC < 0) CYCLE
                     IF (SC%CELLTYPE(JC) == NSCARC_CELLTYPE_NONE) THEN
                        SC%CELLTYPE(JC) = NSCARC_CELLTYPE_SFINE
                        SC%MEASURE(JC) = 0.0_EB
                        DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                           KC = SC%A_COL(JCOL)
                           IF (KC < 0 ) CYCLE
                           IF (SC%CELLTYPE(KC) /= NSCARC_CELLTYPE_NONE) CYCLE
                           IF (STRONGLY_COUPLED(SC%A, SC%A_ROW, JC, JCOL)) SC%MEASURE(KC) = SC%MEASURE(KC)+1
                        ENDDO
                     ENDIF
                  ENDDO 
               ENDIF
            ENDDO INDEPENDENT_SET_LOOP_PMISG
         ENDDO PMISG_LOOP2

CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE , NL, 'SETUP_CELLTYPES', 'MEASURE BEFORE EXCH')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE BEFORE EXCH')
         IF (NMESHES > 1)  THEN
            CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_MEASURE , NL)
            CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_CELLTYPE, NL)
         ENDIF

         IF (MEASURE_GLOBAL_MAX <= EPS) EXIT PMISG_CELLTYPE_LOOP
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE , NL, 'SETUP_CELLTYPES', 'MEASURE AFTER EXCH')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE AFTER EXCH')

      ENDDO PMISG_CELLTYPE_LOOP
         
      

END SELECT


!!!---------------------------------------------------------------------------------------------------------
!!! Exchange celltypes along internal boundaries
!!!---------------------------------------------------------------------------------------------------------
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE FINAL0')
IF (NMESHES > 1) CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_CELLTYPE, NL)
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE FINAL1')



CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_CELLTYPES', 'CELLTYPE FINAL2')
CALL SCARC_DEBUG_QUANTITY(NSCARC_DEBUG_MEASURE , NL, 'SETUP_MEASURES', 'MEASURE FINAL2')

END SUBROUTINE SCARC_SETUP_CELLTYPES




!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set cell types for A1 coarsening
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SET_TYPES_A1(MEASURE, CELLTYPE, JC, OFFSET)
REAL(EB), DIMENSION(:), INTENT(OUT) :: MEASURE
INTEGER , DIMENSION(:), INTENT(OUT) :: CELLTYPE
INTEGER , INTENT(IN) :: JC, OFFSET

MEASURE(JC)         = 0.0_EB
MEASURE(JC-OFFSET)  = 0.0_EB
MEASURE(JC+OFFSET)  = 0.0_EB

CELLTYPE(JC)        = NSCARC_CELLTYPE_SFINE
CELLTYPE(JC-OFFSET) = NSCARC_CELLTYPE_WFINE
CELLTYPE(JC+OFFSET) = NSCARC_CELLTYPE_WFINE
                     
END SUBROUTINE SET_TYPES_A1


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Get maximum measure in internal of mesh (cells along boundaries not regarded)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
REAL(EB) FUNCTION INTERNAL_MAX(MEASURE, NX, NX1, NX2, NY, NY1, NY2, NZ1, NZ2)
REAL(EB), DIMENSION(:), INTENT(IN) :: MEASURE
INTEGER , INTENT(IN) :: NX, NX1, NX2, NY, NY1, NY2, NZ1, NZ2
INTEGER  :: IX, IY, IZ, IC
INTERNAL_MAX = 0.0_EB
DO IZ = NZ1, NZ2
   DO IY = NY1, NY2
      DO IX = NX1, NX2
         IC = (IZ-1) * NX * NY + (IY-1) * NX + IX
         INTERNAL_MAX = MAX(INTERNAL_MAX, MEASURE(IC))
      ENDDO
   ENDDO
ENDDO
RETURN
END FUNCTION INTERNAL_MAX


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Get cell number of internal neighbor for ghost cell IW
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
INTEGER FUNCTION GET_WALL_CELL(WALL, IW, NX, NY)
TYPE (SCARC_WALL_TYPE), DIMENSION(:), INTENT(IN) :: WALL
INTEGER, INTENT(IN) :: IW, NX, NY
INTEGER :: IC

SELECT CASE (TYPE_DIMENSION)
   CASE (NSCARC_DIMENSION_TWO)
      IF (ABS(WALL(IW)%NOM) == 2) THEN
         IC = -1
      ELSE
         IC = (WALL(IW)%IZW-1)*NX + WALL(IW)%IXW
      ENDIF
   CASE (NSCARC_DIMENSION_THREE)
      IC = (WALL(IW)%IZW-1)*NX*NY + (WALL(IW)%IYW-1)*NX + WALL(IW)%IXW
END SELECT

GET_WALL_CELL = IC
RETURN

END FUNCTION GET_WALL_CELL


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform interpolation to coarse level
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_PROLONGATION(NL)
INTEGER , INTENT(IN) :: NL
INTEGER  :: NM, IP, IC, JC, KC, ICOL, JCOL, ICG, ICA
INTEGER  :: IW, IW0, IW2, IDIAG, JDIAG, JCO
REAL(EB) :: SUM_COUPLED, SUM_CPOINTS, SCAL, SUM_COARSE, SUM_DIAG
REAL(EB) :: VALUES(20), WEIGHTS(20)
INTEGER  :: NEIGHBOR(20), NWEIGHTS, NWEIGHTS2
INTEGER  :: COARSE_CELL(20), COARSE_INDEX(20)
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

SELECT_INTERPOLATION: SELECT CASE (TYPE_INTERPOL)

   !!! -------------------------------------------------------------------------------------------------
   !!! Standard interpolation
   !!! -------------------------------------------------------------------------------------------------
   CASE (NSCARC_INTERPOL_STANDARD)

      MESHES_LOOP_STANDARD: DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(*,*) 'Standard interpolatiion not yet implemented'
      ENDDO MESHES_LOOP_STANDARD
      stop

   !!! -------------------------------------------------------------------------------------------------
   !!! Classical interpolation
   !!! -------------------------------------------------------------------------------------------------
   CASE (NSCARC_INTERPOL_CLASSICAL)

      MESHES_LOOP_CLASSICAL: DO NM = NMESHES_MIN, NMESHES_MAX

         SC => SCARC(NM)%COMPACT(NL)
         CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_PROLONGATION','CELLTYPE INIT')
         
         IP = 1
         INTERNAL_CELL_LOOP_CLASSICAL: DO IC = 1, SC%NC
         
            VALUES   = 0.0_EB
            WEIGHTS  = 0.0_EB
            NEIGHBOR = 0
         
            !!!
            !!! If IC is a coarse cell, its value is taken
            !!!
            IF (SC%CELLTYPE(IC) >= NSCARC_CELLTYPE_COARSE) THEN
         
               NEIGHBOR(1)= SC%CELLTYPE(IC)
               WEIGHTS(1) = 1.0_EB
               NWEIGHTS   = 1

            !!!
            !!! If IC is a fine cell, a mean value must be computed based on surrounding coarse cells
            !!!
            ELSE 
         
               !!! Get main diagonal entry a_ii for that fine cell
               IDIAG = SC%A_ROW(IC)
               SUM_DIAG = SC%A(IDIAG)
         
               !!! First search for all neighboring coarse grid cells (store them in NEIGHBOR)
               IW = 1
               DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                  JC = SC%A_COL(ICOL)
                  IF (SC%CELLTYPE(JC) >= NSCARC_CELLTYPE_COARSE) THEN
                     NEIGHBOR(IW) = JC
                     WEIGHTS(IW)  = -SC%A(ICOL)
                     IW = IW + 1
                  ENDIF
               ENDDO
               NWEIGHTS = IW - 1

               !!! Then search for the strongly and weakly coupled fine grid cells
               DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1

                  IW2 = 1
                  SUM_COARSE = 0.0_EB

                  JC = SC%A_COL(ICOL)

                  SELECT CASE (SC%CELLTYPE(JC))

                     CASE (NSCARC_CELLTYPE_SFINE)

                        !!! search for couplings KC of the strongly coupled JC which belong to the 
                        !!! coarse interpolatory set of IC
                        DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                           KC = SC%A_COL(JCOL)

                           NWEIGHTS_SFINE_LOOP: DO IW = 1, NWEIGHTS
                              IF (KC == NEIGHBOR(IW) ) THEN
                                 COARSE_CELL (IW2) = JCOL
                                 COARSE_INDEX(IW2) = IW
                                 SUM_COARSE = SUM_COARSE + SC%A(JCOL)
                                 IW2 = IW2 + 1
                                 EXIT NWEIGHTS_SFINE_LOOP
                              ENDIF
                           ENDDO NWEIGHTS_SFINE_LOOP
                        ENDDO
                        NWEIGHTS2 = IW2 - 1

                        DO IW2 = 1, NWEIGHTS2
                           JCOL = COARSE_CELL(IW2)
                           IW   = COARSE_INDEX(IW2) 
                           WEIGHTS(IW) = WEIGHTS(IW) - SC%A(ICOL)*SC%A(JCOL)/REAL(SUM_COARSE,EB)
                        ENDDO
                        
                     CASE (NSCARC_CELLTYPE_WFINE)
                        
                        SUM_DIAG = SUM_DIAG + SC%A(ICOL) 
                        
                  END SELECT
               ENDDO

               DO IW = 1, NWEIGHTS
                  NEIGHBOR(IW) = SC%CELLTYPE(NEIGHBOR(IW))
                  WEIGHTS(IW)  = WEIGHTS(IW)/SUM_DIAG
               ENDDO

            ENDIF

            !!! 
            !!! Define corresponding entry in interpolation matrix P by means of the upper weights
            !!!
            SC%P_ROW(IC) = IP
            DO IW = 1, NWEIGHTS
               IF  (NEIGHBOR(IW) /= -1) THEN
                  SC%P_COL(IP) = NEIGHBOR(IW)
                  SC%P(IP)     = WEIGHTS(IW)
                  IP = IP +1
               ENDIF
            ENDDO
            SC%P_ROW(SC%NCE+1) = IP

         ENDDO INTERNAL_CELL_LOOP_CLASSICAL
         
      ENDDO MESHES_LOOP_CLASSICAL

   !!! -------------------------------------------------------------------------------------------------
   !!! Direct interpolation
   !!! -------------------------------------------------------------------------------------------------
   CASE (NSCARC_INTERPOL_DIRECT)

      MESHES_LOOP_DIRECT: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SC => SCARC(NM)%COMPACT(NL)
         CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_PROLONGATION','CELLTYPE INIT')
         
         IP = 1
         INTERNAL_CELL_LOOP: DO IC = 1, SC%NC
         
            VALUES   = 0.0_EB
            WEIGHTS  = 0.0_EB
            NEIGHBOR = 0
         
            !!!
            !!! If IC is a coarse cell, its value is taken
            !!!
            IF (SC%CELLTYPE(IC) >= NSCARC_CELLTYPE_COARSE) THEN
         
               NEIGHBOR(1)= SC%CELLTYPE(IC)
               NEIGHBOR(1)= IC
               WEIGHTS(1) = 1.0_EB
               NWEIGHTS   = 1
         
            !!!
            !!! If IC is a fine cell, a mean value must be computed based on surrounding coarse cells
            !!!
            ELSE 
         
               !!! Get main diagonal entry a_ii for that fine cell
               IDIAG = SC%A_ROW(IC)
         
               !!! Select type of fine cell (weakly/strongly coupled)
               SELECT_FPOINT_TYPE: SELECT CASE(SC%CELLTYPE(IC))

                  !!!
                  !!! Strongly coupled fine cell IC
                  !!! approximate IC by weighted sum of surrounding strongly coupled coarse cells JC
                  !!! Note: N_i: all coupled neighboring cells, C_i: all strongly coupled neighboring cells
                  !!!
                  CASE (NSCARC_CELLTYPE_SFINE)
         
                     !!! Compute scaling factor: SCAL = [sum_(k in N_i) a_ik]/[sum_(l in C_i) a_il]
                     SUM_COUPLED = 0.0_EB
                     SUM_CPOINTS = 0.0_EB
         
                     DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                        JC = SC%A_COL(ICOL)
                        SUM_COUPLED = SUM_COUPLED + SC%A(ICOL)
                        IF (SC%CELLTYPE(JC) > 0) SUM_CPOINTS = SUM_CPOINTS + SC%A(ICOL)
                     ENDDO
         
                     SCAL = - SUM_COUPLED/SUM_CPOINTS
         
                     !!! for each coupling of IC compute interpolation weight SCAL * a_ij/a_ii
                     IW = 1
                     DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                        JC = SC%A_COL(ICOL)
                        IF (SC%CELLTYPE(JC) > 0 ) THEN
                           NEIGHBOR(IW) = SC%CELLTYPE(JC)
                           NEIGHBOR(IW) = JC
                           WEIGHTS(IW)  = SCAL * SC%A(ICOL)/SC%A(IDIAG)
                           IW = IW +1
                        ENDIF
                     ENDDO
                     NWEIGHTS = IW - 1
         
                  !!!
                  !!! Weakly coupled fine cell IC:
                  !!! Determine strongly coupled fine cells JC surrounding IC and, in turn, replace 
                  !!! each of them by a mean value of their surrounding strongly coupled coarse cells
                  !!!
                  CASE (NSCARC_CELLTYPE_WFINE)
         
                     IW = 1                                               ! weights counter
                     DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1           ! loop over couplings of weakly coupled fine cell
         
                        !!! regard subdiagonal matrix entries a_ij of weakly coupled fine cell JC to IC
                        JC = SC%A_COL(ICOL)
         
                        !!! Find all surrounding (coupled) points of JC and compute scaling factor 
                        !!! compute scaling factor SCAL = a_ij/a_ii * [sum_(k in N_j) a_jk]/[sum_(l in C_j) ajl] 
                        SUM_COUPLED = 0.0_EB
                        SUM_CPOINTS = 0.0_EB
         
                        DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                           KC = SC%A_COL(JCOL)
                           SUM_COUPLED = SUM_COUPLED + SC%A(JCOL)
                           IF (SC%CELLTYPE(KC) > 0 ) SUM_CPOINTS = SUM_CPOINTS + SC%A(JCOL)
                        ENDDO
         
                        IF (SUM_CPOINTS == 0.0_EB) THEN
                           WRITE(*,*) 'Error in SCARC_INTERPOLATION on mesh ',NM,' for cell ',IC,' with neighbor ', JC, &
                                      'on level ', NL,' stopping program!'
                           WRITE(*,*) '  SUM_COUPLED =',SUM_COUPLED
                           WRITE(*,*) '  SUM_CPOINTS =',SUM_CPOINTS
                           STOP
                        ENDIF
                        SCAL =  SC%A(ICOL)/SC%A(IDIAG) * SUM_COUPLED/SUM_CPOINTS
                            
                        !!! Get diagonal matrix a_jj for point JC
                        JDIAG = SC%A_ROW(JC)
         
                        !!! Compute interpolation weights for all strong coarse cell couplings KC of JC
                        !!! note that a coarse cell KC may be considered several times for different JC's
                        DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                           KC = SC%A_COL(JCOL)
                           IF (SC%CELLTYPE(KC) > 0) THEN
                             NEIGHBOR(IW) = SC%CELLTYPE(KC)
                             NEIGHBOR(IW) = KC
                             WEIGHTS(IW)  = SCAL * SC%A(JCOL)/SC%A(JDIAG)
                             IW = IW +1
                           ENDIF
                        ENDDO
                           
                     ENDDO
                     NWEIGHTS = IW - 1
         
                     !!! make weights unique (add weights for multiple coarse cells)
                     DO IW0 = 1, NWEIGHTS
                        DO IW = IW0+1, NWEIGHTS
                           IF  (NEIGHBOR(IW0) /= -1 .AND. NEIGHBOR(IW) == NEIGHBOR(IW0)) THEN
                              WEIGHTS(IW0) = WEIGHTS(IW0) + WEIGHTS(IW)
                              WEIGHTS(IW)  = 0.0_EB
                              NEIGHBOR(IW) = -1
                           ENDIF
                        ENDDO
                     ENDDO
         
               END SELECT SELECT_FPOINT_TYPE
         
            ENDIF
         
         
            !!! 
            !!! Define corresponding entry in interpolation matrix P by means of the upper weights
            !!!
            SC%P_ROW(IC) = IP
            DO IW = 1, NWEIGHTS
               IF  (NEIGHBOR(IW) /= -1) THEN
                  SC%P_COL(IP) = NEIGHBOR(IW)
                  SC%P(IP)     = WEIGHTS(IW)
                  IP = IP +1
               ENDIF
            ENDDO
         
         ENDDO INTERNAL_CELL_LOOP

         SC%P_ROW(SC%NC+1) = IP
         SC%NROW0 = IP
         
         !!! Determine new coarse number and store it in CELLTYPE
         INTERNAL_CELL_LOOP2: DO IC = 1, SC%NC
            DO ICOL = SC%P_ROW(IC), SC%P_ROW(IC+1)-1
              JC = SC%P_COL(ICOL)
              IF (JC <= SC%NC) THEN                 
                 SC%P_COL(ICOL) = SC%CELLTYPE(JC)         
              ENDIF
            ENDDO
         ENDDO INTERNAL_CELL_LOOP2


         !!! In the multi-mesh case determine the new coarse cell numbers for neighboring cells
         IF (NMESHES > 1) THEN
            GHOST_CELL_LOOP: DO IW = 1, SC%NW
               IF (SC%WALL(IW)%NOM==0) CYCLE GHOST_CELL_LOOP
               ICG = SC%WALL(IW)%ICG(1)
               ICA = SC%WALL(IW)%ICW
               DO ICOL = SC%P_ROW(ICA), SC%P_ROW(ICA+1)-1
                 JC = SC%P_COL(ICOL)
                 IF (JC > SC%NC) THEN
                    JCO = SC%WALL(IW)%ICN(1)
                    SC%P_COL(ICOL) = - JCO
                 ENDIF
               ENDDO
            ENDDO GHOST_CELL_LOOP
         ENDIF

      ENDDO MESHES_LOOP_DIRECT
   

   !!! -------------------------------------------------------------------------------------------------
   !!! Direct interpolation with special treatment of boundary layers
   !!! -------------------------------------------------------------------------------------------------
   CASE (NSCARC_INTERPOL_DIRECT_BDRY)

      MESHES_LOOP_DIRECT_BDRY: DO NM = NMESHES_MIN, NMESHES_MAX
      
         SC => SCARC(NM)%COMPACT(NL)
         CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_CELLTYPE, NL, 'SETUP_PROLONGATION','CELLTYPE INIT')
         
         IP = 1
         INTERNAL_CELL_BDRY_LOOP: DO IC = 1, SC%NC
         
            DIRECT_BDRY_IF: IF (SC%INTERNAL_BDRY_CELL(IC)/=0) THEN

               VALUES   = 0.0_EB
               WEIGHTS  = 0.0_EB
               NEIGHBOR = 0
         
               !!!
               !!! If IC is a coarse cell, its value is taken
               !!!
               IF (SC%CELLTYPE(IC) >= NSCARC_CELLTYPE_COARSE) THEN
         
                  NEIGHBOR(1)= SC%CELLTYPE(IC)
                  NEIGHBOR(1)= IC
                  WEIGHTS(1) = 1.0_EB
                  NWEIGHTS   = 1
         

               !!!
               !!! If IC is a fine cell, a mean value must be computed based on surrounding coarse cells
               !!!
               ELSE 


                  !!! Get main diagonal entry a_ii for that fine cell
                  IDIAG = SC%A_ROW(IC)
         
                  !!! Strongly coupled fine cell IC
                  !!! approximate IC by weighted sum of surrounding strongly coupled coarse cells JC
                  !!! Note: N_i: all coupled neighboring cells, C_i: all strongly coupled neighboring cells
                  !!! Compute scaling factor: SCAL = [sum_(k in N_i) a_ik]/[sum_(l in C_i) a_il]
                  SUM_COUPLED = 0.0_EB
                  SUM_CPOINTS = 0.0_EB
         
                  DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                     JC = SC%A_COL(ICOL)
                     SUM_COUPLED = SUM_COUPLED + SC%A(ICOL)
                     IF (JC > SC%NC) CYCLE
                     IF (SC%INTERNAL_BDRY_CELL(JC)/=0.AND.SC%CELLTYPE(JC)>0) SUM_CPOINTS = SUM_CPOINTS + SC%A(ICOL)
                  ENDDO
         
                  SCAL = - SUM_COUPLED/SUM_CPOINTS
         
                  !!! for each coupling of IC compute interpolation weight SCAL * a_ij/a_ii
                  IW = 1
                  DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                     JC = SC%A_COL(ICOL)
                     IF (JC > SC%NC) CYCLE
                     IF (SC%INTERNAL_BDRY_CELL(JC)/=0.AND.SC%CELLTYPE(JC) > 0 ) THEN
                        NEIGHBOR(IW) = SC%CELLTYPE(JC)
                        NEIGHBOR(IW) = JC
                        WEIGHTS(IW)  = SCAL * SC%A(ICOL)/SC%A(IDIAG)
                        IW = IW +1
                     ENDIF
                  ENDDO
                  NWEIGHTS = IW - 1
         
               ENDIF


            !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! real internal cell !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            ELSE

               VALUES   = 0.0_EB
               WEIGHTS  = 0.0_EB
               NEIGHBOR = 0
         
               !!!
               !!! If IC is a coarse cell, its value is taken
               !!!
               IF (SC%CELLTYPE(IC) >= NSCARC_CELLTYPE_COARSE) THEN
         
                  NEIGHBOR(1)= SC%CELLTYPE(IC)
                  NEIGHBOR(1)= IC
                  WEIGHTS(1) = 1.0_EB
                  NWEIGHTS   = 1
         
               !!!
               !!! If IC is a fine cell, a mean value must be computed based on surrounding coarse cells
               !!!
               ELSE 
         
                  !!! Get main diagonal entry a_ii for that fine cell
                  IDIAG = SC%A_ROW(IC)
         
                  !!! Select type of fine cell (weakly/strongly coupled)
                  SELECT_FPOINT_BDRY_TYPE: SELECT CASE(SC%CELLTYPE(IC))

                     !!!
                     !!! Strongly coupled fine cell IC
                     !!! approximate IC by weighted sum of surrounding strongly coupled coarse cells JC
                     !!! Note: N_i: all coupled neighboring cells, C_i: all strongly coupled neighboring cells
                     !!!
                     CASE (NSCARC_CELLTYPE_SFINE)
         
                        !!! Compute scaling factor: SCAL = [sum_(k in N_i) a_ik]/[sum_(l in C_i) a_il]
                        SUM_COUPLED = 0.0_EB
                        SUM_CPOINTS = 0.0_EB
         
                        DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                           JC = SC%A_COL(ICOL)
                           SUM_COUPLED = SUM_COUPLED + SC%A(ICOL)
                           IF (SC%CELLTYPE(JC) > 0) SUM_CPOINTS = SUM_CPOINTS + SC%A(ICOL)
                        ENDDO
         
                        SCAL = - SUM_COUPLED/SUM_CPOINTS
         
                        !!! for each coupling of IC compute interpolation weight SCAL * a_ij/a_ii
                        IW = 1
                        DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
                           JC = SC%A_COL(ICOL)
                           IF (SC%CELLTYPE(JC) > 0 ) THEN
                              NEIGHBOR(IW) = SC%CELLTYPE(JC)
                              NEIGHBOR(IW) = JC
                              WEIGHTS(IW)  = SCAL * SC%A(ICOL)/SC%A(IDIAG)
                              IW = IW +1
                           ENDIF
                        ENDDO
                        NWEIGHTS = IW - 1

                     !!!
                     !!! Weakly coupled fine cell IC:
                     !!! Determine strongly coupled fine cells JC surrounding IC and, in turn, replace 
                     !!! each of them by a mean value of their surrounding strongly coupled coarse cells
                     !!!
                     CASE (NSCARC_CELLTYPE_WFINE)
            
                        IW = 1                                               ! weights counter
                        DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1           ! loop over couplings of weakly coupled fine cell
         
                           !!! regard subdiagonal matrix entries a_ij of weakly coupled fine cell JC to IC
                           JC = SC%A_COL(ICOL)
            
                           !!! Find all surrounding (coupled) points of JC and compute scaling factor 
                           !!! compute scaling factor SCAL = a_ij/a_ii * [sum_(k in N_j) a_jk]/[sum_(l in C_j) ajl] 
                           SUM_COUPLED = 0.0_EB
                           SUM_CPOINTS = 0.0_EB
            
                           DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                              KC = SC%A_COL(JCOL)
                              SUM_COUPLED = SUM_COUPLED + SC%A(JCOL)
                              IF (SC%CELLTYPE(KC) > 0 ) SUM_CPOINTS = SUM_CPOINTS + SC%A(JCOL)
                           ENDDO
         
                           IF (SUM_CPOINTS == 0.0_EB) THEN
                              WRITE(*,*) 'Error in SCARC_INTERPOLATION on mesh ',NM,' for cell ',IC,' with neighbor ', JC, &
                                         'on level ', NL,' stopping program!'
                              WRITE(*,*) '  SUM_COUPLED =',SUM_COUPLED
                              WRITE(*,*) '  SUM_CPOINTS =',SUM_CPOINTS
                              STOP
                           ENDIF
                           SCAL =  SC%A(ICOL)/SC%A(IDIAG) * SUM_COUPLED/SUM_CPOINTS
                            
                           !!! Get diagonal matrix a_jj for point JC
                           JDIAG = SC%A_ROW(JC)
         
                           !!! Compute interpolation weights for all strong coarse cell couplings KC of JC
                           !!! note that a coarse cell KC may be considered several times for different JC's
                           DO JCOL = SC%A_ROW(JC)+1, SC%A_ROW(JC+1)-1
                              KC = SC%A_COL(JCOL)
                              IF (SC%CELLTYPE(KC) > 0) THEN
                                NEIGHBOR(IW) = SC%CELLTYPE(KC)
                                NEIGHBOR(IW) = KC
                                WEIGHTS(IW)  = SCAL * SC%A(JCOL)/SC%A(JDIAG)
                                IW = IW +1
                              ENDIF
                           ENDDO
                              
                        ENDDO
                        NWEIGHTS = IW - 1
         
                        !!! make weights unique (add weights for multiple coarse cells)
                        DO IW0 = 1, NWEIGHTS
                           DO IW = IW0+1, NWEIGHTS
                              IF  (NEIGHBOR(IW0) /= -1 .AND. NEIGHBOR(IW) == NEIGHBOR(IW0)) THEN
                                 WEIGHTS(IW0) = WEIGHTS(IW0) + WEIGHTS(IW)
                                 WEIGHTS(IW)  = 0.0_EB
                                 NEIGHBOR(IW) = -1
                              ENDIF
                           ENDDO
                        ENDDO
            
                  END SELECT SELECT_FPOINT_BDRY_TYPE
         
               ENDIF
         
         
            ENDIF DIRECT_BDRY_IF
            !!! 
            !!! Define corresponding entry in interpolation matrix P by means of the upper weights
            !!!
            SC%P_ROW(IC) = IP
            DO IW = 1, NWEIGHTS
               IF  (NEIGHBOR(IW) /= -1) THEN
                  SC%P_COL(IP) = NEIGHBOR(IW)
                  SC%P(IP)     = WEIGHTS(IW)
                  IP = IP +1
               ENDIF
            ENDDO
            
         ENDDO INTERNAL_CELL_BDRY_LOOP

         SC%P_ROW(SC%NC+1) = IP
         SC%NROW0 = IP
         
         !!! Determine new coarse number and store it in CELLTYPE
         INTERNAL_CELL_BDRY_LOOP2: DO IC = 1, SC%NC
            DO ICOL = SC%P_ROW(IC), SC%P_ROW(IC+1)-1
              JC = SC%P_COL(ICOL)
              IF (JC <= SC%NC) THEN                 
                 SC%P_COL(ICOL) = SC%CELLTYPE(JC)         
              ENDIF
            ENDDO
         ENDDO INTERNAL_CELL_BDRY_LOOP2

         
      ENDDO MESHES_LOOP_DIRECT_BDRY
   

   !!! -------------------------------------------------------------------------------------------------
   !!! Multipass interpolation
   !!! -------------------------------------------------------------------------------------------------
   CASE (NSCARC_INTERPOL_MULTIPASS)

      MESHES_LOOP_MULTIPASS: DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(*,*) 'Multipass interpolation not yet implemented'
      ENDDO MESHES_LOOP_MULTIPASS
      stop

END SELECT SELECT_INTERPOLATION

IF (NMESHES > 1) CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_WEIGHTS, NL)
   
END SUBROUTINE SCARC_SETUP_PROLONGATION


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Define restriction matrix R (currently transpose of prolongation matrix P)
!!!  - In spite of the additinal need for the storing of R, this is done to save computational time
!!!  - during the later matrix transfer operations 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_RESTRICTION(NL)
INTEGER , INTENT(IN) :: NL
INTEGER  :: NM, NOM, ICP, ICP2, IC, IC2, IG, IG0, ICC
LOGICAL  :: BFIRST
TYPE (OSCARC_TYPE), POINTER :: OS
TYPE (SCARC_COMPACT_TYPE) , POINTER :: SC
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSC

MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

   SC => SCARC(NM)%COMPACT(NL)
   
   IC2 = 1
   DO ICP = 1, SC%NCCE
      BFIRST = .TRUE.
      DO IC = 1, SC%NCE
         
         ROW_LOOP: DO ICP2 = SC%P_ROW(IC),SC%P_ROW(IC+1)-1
            IF (SC%P_COL(ICP2) == ICP) THEN
               SC%R(IC2) = SC%P(ICP2)
               IF (BFIRST) THEN
                  SC%R_ROW(ICP) = IC2
               ENDIF
               SC%R_COL(IC2) = IC
               IC2 = IC2 + 1
               BFIRST = .FALSE.
               EXIT ROW_LOOP
            ENDIF
         ENDDO ROW_LOOP
   
      ENDDO
   
   ENDDO
   SC%R_ROW(SC%NCCE+1)=IC2

   OTHER_MESHES_LOOP: DO NOM = 1, NMESHES

      IF (NOM == NM) CYCLE OTHER_MESHES_LOOP
      OS  => SCARC(NM)%OSCARC(NOM)      
      IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE OTHER_MESHES_LOOP
      OSC  => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)      

      IC2 = 1
      ICC = 0
      OTHER_GHOSTCELL_LOOP: DO IG0 = 1, OSC%NG
 
         ICP = OSC%CELLTYPE(IG0)
         IF (ICP < NSCARC_CELLTYPE_COARSE) CYCLE OTHER_GHOSTCELL_LOOP
         ICC = ICC + 1

         BFIRST = .TRUE.
         DO IG = 1, OSC%NG
         
            OTHER_ROW_LOOP: DO ICP2 = OSC%P_ROW(IG),OSC%P_ROW(IG+1)-1
               IF (OSC%P_COL(ICP2) == ICC) THEN
                  OSC%R(IC2) = OSC%P(ICP2)
                  IF (BFIRST) THEN
                     OSC%R_ROW(ICC) = IC2
                  ENDIF
                  OSC%R_COL(IC2) = IG
                  IC2 = IC2 + 1
                  BFIRST = .FALSE.
                  EXIT OTHER_ROW_LOOP
               ENDIF
            ENDDO OTHER_ROW_LOOP
   
         ENDDO
     
      ENDDO OTHER_GHOSTCELL_LOOP
      OSC%R_ROW(ICC+1)=IC2

   ENDDO OTHER_MESHES_LOOP

ENDDO MESHES_LOOP

  
CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_RESTRICTION, NL, 'SETUP_RESTRICTION', 'FINAL RESTRICT')
END SUBROUTINE SCARC_SETUP_RESTRICTION


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Compute coarser matrix A_coarse by use of interpolation matrices:
!!!
!!!      A_coarse = I_fine^coarse * A_fine * I_coarse_fine
!!! 
!!! Note the different storage techniques (compact storage technique for 
!!! transfer matrices and coarse matrix, banded for finest matrix)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_TRANSFER_MATRIX(NL)
INTEGER , INTENT(IN) :: NL
INTEGER :: NM, IC, ICO2, IERR, ICP1, ICP2, IP, ICOL, IDIAG
REAL (EB), ALLOCATABLE, DIMENSION(:) :: VAL
!REAL(EB):: MAUX1(50,50)=0.0_EB!, MAUX2(30,30)=0.0_EB
REAL:: AUX1, AUX2, PW
TYPE (SCARC_COMPACT_TYPE), POINTER :: SCF, SCC

IERR = 0

MESHES_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX

   SCF => SCARC(NM)%COMPACT(NL)             ! pointer to fine level
   SCC => SCARC(NM)%COMPACT(NL+1)           ! pointer to coarse level
   
   IF (NMESHES==1) THEN
      ALLOCATE (VAL(SCF%NC), STAT=IERR)
   ELSE
      ALLOCATE (VAL(SCF%NCE), STAT=IERR)
   ENDIF
   CALL CHKMEMERR ('SCARC_TRANSFER_MATRIX', 'VAL', IERR)
   VAL = 0.0_EB
   
   ICP1_LOOP: DO ICP1 = 1, SCF%NCC


      !!! -------------------------------------------------------------------------------------
      !!! First: loop over the internal coarse cells
      !!! -------------------------------------------------------------------------------------
      ICP2_LOOP1: DO ICP2 = 1, SCF%NCCE

         AUX2 = 0.0_EB
         
         DO IC = 1, SCF%NC
   
            IDIAG = SCF%A_ROW(IC)
            PW    = P_WEIGHT(IC, ICP2, NM, NL)
            AUX1  = SCF%A(IDIAG) * PW
   
            COUPLINGS_LOOP: DO ICOL = SCF%A_ROW(IC)+1, SCF%A_ROW(IC+1)-1
               ICO2  = SCF%A_COL(ICOL)
               PW = P_WEIGHT(ICO2, ICP2, NM, NL)
               AUX1 = AUX1 + SCF%A(ICOL) * PW
            ENDDO COUPLINGS_LOOP
            
            AUX2 = AUX2 + P_WEIGHT(IC, ICP1, NM, NL) * AUX1

         ENDDO
         VAL(ICP2) = AUX2

      ENDDO ICP2_LOOP1
   
      !!! analyze new matrix line and store it corresponding to compact storage technique:
      !!! (diagonal entry first)
      SCC%A(IP)       = VAL(ICP1)
      SCC%A_ROW(ICP1) = IP
      SCC%A_COL(IP)   = ICP1
   
      IP  = IP + 1
      ICP2_LOOP3: DO ICP2 = 1, SCF%NCCE
      !DO ICP2 = 1, SCF%NCC
         IF (ICP2 /= ICP1 .AND. ABS(VAL(ICP2)) >= 1.0E-12_EB) THEN
            SCC%A(IP)     = VAL(ICP2)
            SCC%A_COL(IP) = ICP2
            IP  = IP + 1
         ENDIF
      ENDDO ICP2_LOOP3
   
      VAL = 0.0_EB
   ENDDO ICP1_LOOP

   SCC%A_ROW(SCC%NC+1) = IP
   SCC%NA = IP - 1
   
   DEALLOCATE(VAL)
   
ENDDO MESHES_LOOP

CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIX, NL+1, 'TRANSFER_MATRIX', 'Next coarser matrix1')
TYPE_MATRIX = NSCARC_MATRIX_SUBDIAG
IF (NMESHES > 1) CALL SCARC_EXCHANGE(NSCARC_EXCHANGE_MATRIX, NL)

CALL SCARC_DEBUG_QUANTITY (NSCARC_DEBUG_MATRIX, NL+1, 'TRANSFER_MATRIX', 'Next coarser matrix2')


END SUBROUTINE SCARC_TRANSFER_MATRIX


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if corresponding coarse point contributes a non-zero interpolation weight or not
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
REAL(EB) FUNCTION P_WEIGHT(IC, ICP, NM, NL)
INTEGER, INTENT(IN):: IC, ICP, NM, NL
INTEGER :: ICOL
REAL(EB) :: VAL
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

SC => SCARC(NM)%COMPACT(NL)           

VAL = 0.0_EB
!IF (IC <= SC%NC) THEN
   P_WEIGHT_LOOP: DO ICOL = SC%P_ROW(IC), SC%P_ROW(IC+1)-1
      IF (ICOL > 0) THEN
        IF (SC%P_COL(ICOL) /= ICP) CYCLE P_WEIGHT_LOOP
      ENDIF
      VAL = SC%P(ICOL)
   ENDDO P_WEIGHT_LOOP
!ENDIF

P_WEIGHT = VAL
RETURN 
END FUNCTION P_WEIGHT

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Determine if corresponding coarse point contributes a non-zero interpolation weight or not
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
REAL(EB) FUNCTION R_WEIGHT(IC, ICP, NM, NL)
INTEGER, INTENT(IN):: IC, ICP, NM, NL
INTEGER :: ICOL
REAL(EB) :: VAL
TYPE (SCARC_COMPACT_TYPE) , POINTER :: SC

SC => SCARC(NM)%COMPACT(NL)           

VAL = 0.0_EB
IF (ICP <= SC%NCC) THEN
   R_WEIGHT_LOOP: DO ICOL = SC%P_ROW(IC), SC%P_ROW(IC+1)-1
      IF (ICOL > 0) THEN
        IF (SC%P_COL(ICOL) /= ICP) CYCLE R_WEIGHT_LOOP
      ENDIF
      VAL = SC%P(ICOL)
   ENDDO R_WEIGHT_LOOP
ELSE
  WRITE(*,*) 
ENDIF

R_WEIGHT = VAL
RETURN 
END FUNCTION R_WEIGHT


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Interface for the call of ScaRC-solver with requested storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SOLVER
REAL (EB) :: TNOW_SOLVER

TNOW_SOLVER = SECOND()

SELECT_METHOD: SELECT CASE (TYPE_METHOD)

   !!! Krylov method (CG/BICG)
   CASE (NSCARC_METHOD_KRYLOV)

      SELECT_KRYLOV: SELECT CASE (TYPE_KRYLOV)
         CASE (NSCARC_KRYLOV_CG)                           
            CALL SCARC_METHOD_CG  (NSCARC_SCOPE_MAIN, NSCARC_VECTOR_F, TYPE_PRECON)
         CASE (NSCARC_KRYLOV_BICG)                         
            CALL SCARC_METHOD_BICG(NSCARC_SCOPE_MAIN, NSCARC_VECTOR_F, TYPE_PRECON)
      END SELECT SELECT_KRYLOV

   !!! Multigrid method
   CASE (NSCARC_METHOD_MULTIGRID)

      CALL SCARC_METHOD_MULTIGRID(NSCARC_SCOPE_MAIN, NSCARC_VECTOR_F, TYPE_SMOOTH)

END SELECT SELECT_METHOD

TUSED_SCARC(NSCARC_TIME_SOLVER  ,:)=TUSED_SCARC(NSCARC_TIME_SOLVER  ,:)+SECOND()-TNOW_SOLVER
TUSED_SCARC(NSCARC_TIME_TOTAL,:)=TUSED_SCARC(NSCARC_TIME_TOTAL,:)+SECOND()-TNOW_SOLVER
END SUBROUTINE SCARC_SOLVER


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!! Set pointer to chosen vector for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FUNCTION POINT_TO_BVECTOR(NVECTOR, NM, NL)
REAL(EB), POINTER, DIMENSION(:,:,:) :: POINT_TO_BVECTOR
INTEGER, INTENT(IN):: NVECTOR, NM, NL

SELECT CASE (NVECTOR)
   CASE (NSCARC_VECTOR_F)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%F
   CASE (NSCARC_VECTOR_X)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%X
   CASE (NSCARC_VECTOR_D)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%D
   CASE (NSCARC_VECTOR_Y)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%Y
   CASE (NSCARC_VECTOR_G)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%G
   CASE (NSCARC_VECTOR_W)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%W
   CASE (NSCARC_VECTOR_Z)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%Z
   CASE (NSCARC_VECTOR_X2)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%X2
   CASE (NSCARC_VECTOR_D2)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%D2
   CASE (NSCARC_VECTOR_Y2)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%Y2
   CASE (NSCARC_VECTOR_G2)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%G2
   CASE (NSCARC_VECTOR_W2)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%W2
   CASE (NSCARC_VECTOR_Z2)
      POINT_TO_BVECTOR => SCARC(NM)%BANDED(NL)%Z2
   CASE (NSCARC_VECTOR_H)
      POINT_TO_BVECTOR => MESHES(NM)%H
   CASE (NSCARC_VECTOR_HS)
      POINT_TO_BVECTOR => MESHES(NM)%HS
END SELECT

RETURN
END FUNCTION POINT_TO_BVECTOR


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!! Set pointer to chosen vector for compact storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FUNCTION POINT_TO_CVECTOR(NVECTOR, NM, NL)
REAL(EB), POINTER, DIMENSION(:) :: POINT_TO_CVECTOR
INTEGER, INTENT(IN):: NVECTOR, NM, NL

SELECT CASE (NVECTOR)
   CASE (NSCARC_VECTOR_F)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%F
   CASE (NSCARC_VECTOR_X)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%X
   CASE (NSCARC_VECTOR_D)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%D
   CASE (NSCARC_VECTOR_Y)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%Y
   CASE (NSCARC_VECTOR_G)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%G
   CASE (NSCARC_VECTOR_W)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%W
   CASE (NSCARC_VECTOR_Z)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%Z
   CASE (NSCARC_VECTOR_X2)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%X2
   CASE (NSCARC_VECTOR_D2)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%D2
   CASE (NSCARC_VECTOR_Y2)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%Y2
   CASE (NSCARC_VECTOR_G2)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%G2
   CASE (NSCARC_VECTOR_W2)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%W2
   CASE (NSCARC_VECTOR_Z2)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%Z2
   CASE (NSCARC_VECTOR_MEASURE)
      POINT_TO_CVECTOR => SCARC(NM)%COMPACT(NL)%MEASURE
END SELECT

RETURN
END FUNCTION POINT_TO_CVECTOR


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!! Set pointer to chosen vector for compact storage technique for neighbor
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FUNCTION POINT_TO_NEIGHBORING_CVECTOR_REAL(NVECTOR, NM, NOM, NL)
REAL(EB), POINTER, DIMENSION(:) :: POINT_TO_NEIGHBORING_CVECTOR_REAL
INTEGER, INTENT(IN):: NVECTOR, NM, NOM, NL

SELECT CASE (NVECTOR)
   CASE (NSCARC_VECTOR_X)
      POINT_TO_NEIGHBORING_CVECTOR_REAL => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)%X
   CASE (NSCARC_VECTOR_MEASURE)
      POINT_TO_NEIGHBORING_CVECTOR_REAL => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)%MEASURE
END SELECT

RETURN
END FUNCTION POINT_TO_NEIGHBORING_CVECTOR_REAL


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!! Set pointer to chosen vector for compact storage technique for neighbor
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FUNCTION POINT_TO_NEIGHBORING_CVECTOR_INT(NVECTOR, NM, NOM, NL)
INTEGER, POINTER, DIMENSION(:) :: POINT_TO_NEIGHBORING_CVECTOR_INT
INTEGER, INTENT(IN):: NVECTOR, NM, NOM, NL

SELECT CASE (NVECTOR)
   CASE (NSCARC_VECTOR_CELLTYPE)
      POINT_TO_NEIGHBORING_CVECTOR_INT => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)%CELLTYPE
END SELECT

RETURN
END FUNCTION POINT_TO_NEIGHBORING_CVECTOR_INT


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!! Set pointer to chosen vector for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FUNCTION POINT_TO_CVECTOR_INT(NVECTOR, NM, NL)
INTEGER, POINTER, DIMENSION(:) :: POINT_TO_CVECTOR_INT
INTEGER, INTENT(IN):: NVECTOR, NM, NL

SELECT CASE (NVECTOR)
   CASE (NSCARC_VECTOR_CELLTYPE)
      POINT_TO_CVECTOR_INT => SCARC(NM)%COMPACT(NL)%CELLTYPE
END SELECT

END FUNCTION POINT_TO_CVECTOR_INT


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Compute global matrix-vector product (including data exchange along internal boundaries)
!!! for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_MATVEC_PRODUCT(NVECTOR1, NVECTOR2, NL)
INTEGER , INTENT(IN):: NVECTOR1, NVECTOR2, NL
REAL(EB), POINTER, DIMENSION(:,:,:) :: VB1, VB2
REAL(EB), POINTER, DIMENSION(:)     :: VC1, VC2
REAL(EB), POINTER, DIMENSION(:,:)   :: AB
REAL(EB), POINTER, DIMENSION(:)     :: AC
INTEGER , POINTER, DIMENSION(:)     :: AC_ROW, AC_COL
INTEGER , POINTER :: NX, NY, NZ, NC
INTEGER :: NM, I, J, K, IC, JC, ICOL


!!!----------------------------------------------------------------------------------------------------
!!! Exchange internal boundary values of vector1 such that the ghost values contain the corresponding
!!! overlapped values of adjacent neighbor
!!!----------------------------------------------------------------------------------------------------
TYPE_VECTOR = NVECTOR1
IF (NMESHES > 1) CALL SCARC_EXCHANGE (NSCARC_EXCHANGE_VECTOR, NL)

!!!----------------------------------------------------------------------------------------------------
!!! Perform global matrix-vector product:
!!! Note: - matrix already contains subdiagonal values from neighbor along internal boundaries
!!!       - if vector1 contains neighboring values, then correct values of global matvec are achieved
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         VB1 => POINT_TO_BVECTOR (NVECTOR1, NM, NL)
         VB2 => POINT_TO_BVECTOR (NVECTOR2, NM, NL)
         
         NX => SCARC(NM)%BANDED(NL)%NX                                     
         NY => SCARC(NM)%BANDED(NL)%NY
         NZ => SCARC(NM)%BANDED(NL)%NZ

         AB => SCARC(NM)%BANDED(NL)%A                                        ! system matrix
      
         SELECT CASE (TYPE_DIMENSION)
            
            CASE (NSCARC_DIMENSION_TWO)
      
               DO K = 1, NZ
                  DO I = 1, NX
                     IC = (K-1) * NX + I
                     VB2(I, 1, K) =   (  AB(IC, ID ) * VB1(I  , 1, K  )   &         ! diagonal component
                                       + AB(IC, ILZ) * VB1(I  , 1, K-1)   &         ! lower z-component
                                       + AB(IC, ILX) * VB1(I-1, 1, K  )   &         ! lower x-component
                                       + AB(IC, IUX) * VB1(I+1, 1, K  )   &         ! upper x-component
                                       + AB(IC, IUZ) * VB1(I  , 1, K+1) )           ! upper z-component
                  ENDDO
               ENDDO
         
            CASE (NSCARC_DIMENSION_THREE)
      
               DO K = 1, NZ
                  DO J = 1, NY
                     DO I = 1, NX
                        IC = (K-1) * NX * NY + (J-1) * NX + I
                        VB2(I, J, K) =  ( AB(IC, ID ) * VB1(I  , J  , K  )   &      ! diagonal component
                                      +   AB(IC, ILZ) * VB1(I  , J  , K-1)   &      ! lower z-component
                                      +   AB(IC, ILY) * VB1(I  , J-1, K  )   &      ! lower y-component
                                      +   AB(IC, ILX) * VB1(I-1, J  , K  )   &      ! lower x-component
                                      +   AB(IC, IUX) * VB1(I+1, J  , K  )   &      ! upper x-component
                                      +   AB(IC, IUY) * VB1(I  , J+1, K  )   &      ! upper y-component
                                      +   AB(IC, IUZ) * VB1(I  , J  , K+1) )        ! upper z-component
                     ENDDO
                  ENDDO
               ENDDO
         
         END SELECT
      
      ENDDO 
   
   !!! ---------------------------- Compact storage technique -----------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         VC1 => POINT_TO_CVECTOR (NVECTOR1, NM, NL)
         VC2 => POINT_TO_CVECTOR (NVECTOR2, NM, NL)
         
         NC     => SCARC(NM)%COMPACT(NL)%NC                                   ! number of cells

         AC     => SCARC(NM)%COMPACT(NL)%A                                    ! system matrix
         AC_ROW => SCARC(NM)%COMPACT(NL)%A_ROW                                ! row pointer
         AC_COL => SCARC(NM)%COMPACT(NL)%A_COL                                ! column pointer
      
         DO IC = 1, NC
                 
            !!! diagonal entry
            ICOL = AC_ROW(IC)                             
            JC   = AC_COL(ICOL)
      
            VC2 (IC) = AC(ICOL)* VC1(JC)
      
            !!! subdiagonal entries
            DO ICOL = AC_ROW(IC)+1, AC_ROW(IC+1)-1          
               JC = AC_COL(ICOL)
               VC2(IC) =  VC2(IC) + AC(ICOL)* VC1(JC)
            ENDDO
      
         ENDDO
      
      ENDDO 
      
END SELECT

END SUBROUTINE SCARC_MATVEC_PRODUCT


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Compute global scalarproductt (including global data exchange) for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
REAL(EB) FUNCTION SCARC_SCALAR_PRODUCT(NVECTOR1, NVECTOR2, NL)
INTEGER, INTENT(IN):: NVECTOR1, NVECTOR2, NL
REAL(EB), DIMENSION(:,:,:), POINTER ::  VB1, VB2
REAL(EB), DIMENSION(:)    , POINTER ::  VC1, VC2
INTEGER , POINTER :: NX, NY, NZ, NC
INTEGER  :: NM, IERR, NL0, I, J, K, IC
REAL(EB) :: SP_GLOBAL
! MKL code
!REAL(EB) :: DDOT
!EXTERNAL :: DDOT

!!!----------------------------------------------------------------------------------------------------
!!! Compute local scalarproduct
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         VB1 => POINT_TO_BVECTOR (NVECTOR1, NM, NL)
         VB2 => POINT_TO_BVECTOR (NVECTOR2, NM, NL)
         
         NX  => SCARC(NM)%BANDED(NL)%NX
         NY  => SCARC(NM)%BANDED(NL)%NY
         NZ  => SCARC(NM)%BANDED(NL)%NZ
      
         SP_LOCAL(NM) = 0.0_EB
         DO K = 1, NZ
            DO J = 1, NY
               DO I = 1, NX
                  SP_LOCAL(NM) = SP_LOCAL(NM) + VB1 (I, J, K) * VB2 (I, J, K)
               ENDDO
            ENDDO
         ENDDO
      
      ENDDO

   !!! ---------------------------- Compact storage technique -----------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         VC1 => POINT_TO_CVECTOR (NVECTOR1, NM, NL)
         VC2 => POINT_TO_CVECTOR (NVECTOR2, NM, NL)
         
         NC  => SCARC(NM)%COMPACT(NL)%NC
      
         !IF (SCARC_MKL) THEN
         !   SP_LOCAL(NM) = DDOT(NC, VC1, 1, VC2, 1)
         !ELSE
            SP_LOCAL(NM) = 0.0_EB
            DO IC = 1, NC
               SP_LOCAL(NM) = SP_LOCAL(NM) + VC1(IC) * VC2(IC)
            ENDDO
         !ENDIF
      
      ENDDO

END SELECT

!!!----------------------------------------------------------------------------------------------------
!!! get global scalarproduct by a global summation of the local values
!!!----------------------------------------------------------------------------------------------------
IERR = 0
NL0  = NL
SP_GLOBAL   = 0.0_EB
IF (NMESHES>1 .AND. USE_MPI) THEN
   CALL MPI_ALLREDUCE (SP_LOCAL(MYID+1), SP_GLOBAL, 1, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, IERR)
ELSE
   DO NM=1,NMESHES
      SP_GLOBAL = SP_GLOBAL + SP_LOCAL(NM)
   ENDDO
ENDIF

SCARC_SCALAR_PRODUCT = SP_GLOBAL
RETURN

END FUNCTION SCARC_SCALAR_PRODUCT


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Compute global L2-norm (including global data exchange) for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
REAL(EB) FUNCTION SCARC_L2NORM(NVECTOR1, NL)
INTEGER, INTENT(IN):: NVECTOR1, NL
REAL(EB), DIMENSION(:,:,:), POINTER ::  VB
REAL(EB), DIMENSION(:)    , POINTER ::  VC
INTEGER , POINTER :: NX, NY, NZ, NC
INTEGER  :: NM, IERR, I, J, K, IC
REAL(EB) :: SP_GLOBAL  
REAL(EB) :: DDOT
EXTERNAL :: DDOT

!!!----------------------------------------------------------------------------------------------------
!!! Compute local scalarproduct
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         VB => POINT_TO_BVECTOR (NVECTOR1, NM, NL)

         NX => SCARC(NM)%BANDED(NL)%NX
         NY => SCARC(NM)%BANDED(NL)%NY
         NZ => SCARC(NM)%BANDED(NL)%NZ
      
         SP_LOCAL(NM) = 0.0_EB
         DO K = 1, NZ
            DO J = 1, NY
               DO I = 1, NX
                  SP_LOCAL(NM) = SP_LOCAL(NM) + VB (I, J, K) * VB (I, J, K)
               ENDDO
            ENDDO
         ENDDO
      ENDDO
      
   !!! ---------------------------- Compact storage technique -----------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         VC => POINT_TO_CVECTOR (NVECTOR1, NM, NL)
      
         NC => SCARC(NM)%COMPACT(NL)%NC
      
         !IF (SCARC_MKL) THEN
         !   SP_LOCAL(NM) = DDOT(NC, VC, 1, VC, 1)
         !ELSE
            SP_LOCAL(NM) = 0.0_EB
            DO IC = 1, NC
               SP_LOCAL(NM) = SP_LOCAL(NM) + VC(IC) * VC(IC)
            ENDDO
         !ENDIF

      ENDDO

END SELECT

!!!----------------------------------------------------------------------------------------------------
!!! get global scalarproduct by a global summation of the local values
!!!----------------------------------------------------------------------------------------------------
IERR = 0
SP_GLOBAL = 0.0_EB
IF (NMESHES>1 .AND. USE_MPI) THEN
   CALL MPI_ALLREDUCE (SP_LOCAL(MYID+1), SP_GLOBAL, 1, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, IERR)
ELSE
   DO NM=1,NMESHES
      SP_GLOBAL = SP_GLOBAL + SP_LOCAL(NM)
   ENDDO
ENDIF
SP_GLOBAL = SQRT (SP_GLOBAL/REAL(NC_GLOBAL(NL), EB))   

SCARC_L2NORM = SP_GLOBAL
RETURN

END FUNCTION SCARC_L2NORM



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Compute linear combination of two vectors for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_VECTOR_SUM(NVECTOR1, NVECTOR2, SCAL1, SCAL2, NL)
INTEGER , INTENT(IN):: NVECTOR1, NVECTOR2, NL
REAL(EB), INTENT(IN):: SCAL1, SCAL2
REAL(EB), DIMENSION(:,:,:), POINTER ::  VB1, VB2
REAL(EB), DIMENSION(:)    , POINTER ::  VC1, VC2
INTEGER  :: NM
! MKL code
!INTEGER , POINTER :: NC
!EXTERNAL :: DAXPBY

SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX

         VB1 => POINT_TO_BVECTOR(NVECTOR1, NM, NL)
         VB2 => POINT_TO_BVECTOR(NVECTOR2, NM, NL)

         VB2 = SCAL1 * VB1 + SCAL2 * VB2

      ENDDO

   !!! ---------------------------- Compact storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX

         VC1 => POINT_TO_CVECTOR(NVECTOR1, NM, NL)
         VC2 => POINT_TO_CVECTOR(NVECTOR2, NM, NL)

         !IF (SCARC_MKL) THEN
         !   NC  => SCARC(NM)%COMPACT(NL)%NC
         !   CALL DAXPBY(NC, SCAL1, VC1, 1, SCAL2, VC2, 1)
         !ELSE
           VC2 = SCAL1 * VC1 + SCAL2 * VC2
         !ENDIF

      ENDDO

END SELECT

END SUBROUTINE SCARC_VECTOR_SUM



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Define vector2 to be a scaled copy of vector 1 for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_VECTOR_COPY(NVECTOR1, NVECTOR2, SCAL1, NL)
INTEGER , INTENT(IN):: NVECTOR1, NVECTOR2, NL
REAL(EB), INTENT(IN):: SCAL1
REAL(EB), DIMENSION(:,:,:), POINTER ::  VB1, VB2
REAL(EB), DIMENSION(:)    , POINTER ::  VC1, VC2
INTEGER  :: NM
!!! MKL code
!INTEGER , POINTER :: NC
!EXTERNAL :: DCOPY, DSCAL

SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX

         VB1 => POINT_TO_BVECTOR(NVECTOR1, NM, NL)
         VB2 => POINT_TO_BVECTOR(NVECTOR2, NM, NL)

         VB2 = SCAL1 * VB1 

      ENDDO

   !!! ---------------------------- Compact storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX

         VC1 => POINT_TO_CVECTOR(NVECTOR1, NM, NL)
         VC2 => POINT_TO_CVECTOR(NVECTOR2, NM, NL)

         !IF (SCARC_MKL) THEN
         !   NC  => SCARC(NM)%COMPACT(NL)%NC
         !   CALL DCOPY(NC, VC1, 1, VC2, 1)
         !   CALL DSCAL(NC, SCAL1, VC2, 1)
         !ELSE
            VC2 = SCAL1 * VC1
         !ENDIF

      ENDDO

END SELECT

END SUBROUTINE SCARC_VECTOR_COPY


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Clear vector
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_VECTOR_CLEAR(NVECTOR, NL)
INTEGER , INTENT(IN):: NVECTOR, NL
REAL(EB), DIMENSION(:,:,:), POINTER ::  VB
REAL(EB), DIMENSION(:)    , POINTER ::  VC
INTEGER  :: NM

SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
         VB => POINT_TO_BVECTOR(NVECTOR, NM, NL)
         VB =  0.0_EB
      ENDDO

   !!! ---------------------------- Compact storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
         VC => POINT_TO_CVECTOR(NVECTOR, NM, NL)
         VC =  0.0_EB
      ENDDO

END SELECT

END SUBROUTINE SCARC_VECTOR_CLEAR

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Define vector to a scalar value
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_VECTOR_DEFINE(NVECTOR, SCAL, NL)
INTEGER , INTENT(IN):: NVECTOR, NL
REAL(EB), INTENT(IN):: SCAL
REAL(EB), DIMENSION(:,:,:), POINTER ::  VB
REAL(EB), DIMENSION(:)    , POINTER ::  VC
INTEGER  :: NM

SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
         VB => POINT_TO_BVECTOR(NVECTOR, NM, NL)
         VB =  SCAL
      ENDDO

   !!! ---------------------------- Compact storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
         VC => POINT_TO_CVECTOR(NVECTOR, NM, NL)
         VC =  SCAL
      ENDDO

END SELECT

END SUBROUTINE SCARC_VECTOR_DEFINE



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform preconditioning for banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PRECONDITIONING (NVECTOR1, NVECTOR2, NL, NSCOPE)
USE POIS, ONLY: H2CZSS, H3CZSS
INTEGER, INTENT(IN):: NVECTOR1, NVECTOR2, NL, NSCOPE
REAL(EB), DIMENSION(:,:,:), POINTER ::  VB1, VB2, FFT
REAL(EB), DIMENSION(:)    , POINTER ::  VC1, VC2
REAL(EB), DIMENSION(:,:)  , POINTER ::  AB
REAL(EB), DIMENSION(:)    , POINTER ::  AC
INTEGER , DIMENSION(:)    , POINTER ::  AC_ROW, AC_COL
INTEGER , POINTER:: NX, NY, NZ, NC
INTEGER  :: NPRECON, NM, I, J, K, IC, ICOL
REAL(EB) :: AUX, OMEGA=1.5_EB
TYPE (MESH_TYPE), POINTER :: M

SELECT CASE (NSCOPE)
   CASE (NSCARC_SCOPE_MAIN)
      NPRECON = TYPE_PRECON
   CASE (NSCARC_SCOPE_PRECON)
      NPRECON = TYPE_SMOOTH
   CASE (NSCARC_SCOPE_COARSE)
      NPRECON = NSCARC_PRECON_SSOR
END SELECT

SELECT CASE (TYPE_SYSTEM)

   !!! ---------------------------- Banded storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      SELECT CASE (NPRECON)
      
         !!!--------------------------------------------------------------------------------------------
         !!! Multigrid preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_MULTIGRID)
      
            CALL SCARC_METHOD_MULTIGRID (NSCARC_SCOPE_PRECON, NVECTOR2, TYPE_SMOOTH)
      
         !!!--------------------------------------------------------------------------------------------
         !!! Jacobi preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_JACOBI)
      
            DO NM = NMESHES_MIN, NMESHES_MAX
      
               VB2 => POINT_TO_BVECTOR(NVECTOR2, NM, NL)
         
               NX => SCARC(NM)%BANDED(NL)%NX
               NY => SCARC(NM)%BANDED(NL)%NY
               NZ => SCARC(NM)%BANDED(NL)%NZ
               AB => SCARC(NM)%BANDED(NL)%A
      
               DO K = 1, NZ
                  DO J = 1, NY
                     DO I = 1, NX
                        IC = (K-1) * NX * NY + (J-1) * NX + I
                        VB2 (I, J, K) = VB2 (I, J, K) / AB(IC, ID)
                     ENDDO
                  ENDDO
               ENDDO
      
            ENDDO
         
         !!!--------------------------------------------------------------------------------------------
         !!! SSOR preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_SSOR)
         
            DO NM = NMESHES_MIN, NMESHES_MAX
            
               VB2 => POINT_TO_BVECTOR(NVECTOR2, NM, NL)
         
               NX => SCARC(NM)%BANDED(NL)%NX
               NY => SCARC(NM)%BANDED(NL)%NY
               NZ => SCARC(NM)%BANDED(NL)%NZ
               NC => SCARC(NM)%BANDED(NL)%NC
               AB => SCARC(NM)%BANDED(NL)%A
         
               SELECT CASE (TYPE_DIMENSION)
               
                  CASE (NSCARC_DIMENSION_TWO)
               
                     DO K = 1, NZ
                        DO I = 1, NX
                           IC = (K-1) * NX + I
                           AUX =    AB(IC,ILZ) * VB2 (I  , 1, K-1)  &
                                  + AB(IC,ILX) * VB2 (I-1, 1, K  )
                           VB2 (I, 1, K) = (VB2(I, 1, K) - AUX*OMEGA) / AB(IC,ID)
                        ENDDO
                     ENDDO
                     DO K = NZ, 1, - 1
                        DO I = NX, 1, - 1
                           IC = (K-1) * NX + I
                           IF (IC==NC) CYCLE
                           AUX =    AB(IC,IUZ) * VB2 (I  , 1, K+1) &
                                  + AB(IC,IUX) * VB2 (I+1, 1, K  )
                           VB2 (I, 1, K) = VB2 (I, 1, K) - AUX * OMEGA / AB(IC,ID)
                        ENDDO
                     ENDDO
               
                  CASE (NSCARC_DIMENSION_THREE)
               
                     DO K = 1, NZ
                        DO J = 1, NY
                           DO I = 1, NX
                              IC = (K-1) * NX * NY + (J-1) * NX + I
                              AUX =    AB(IC,ILZ) * VB2 (I  , J  , K-1) &
                                     + AB(IC,ILY) * VB2 (I  , J-1, K  ) &
                                     + AB(IC,ILX) * VB2 (I-1, J  , K  )
                             VB2 (I, J, K) = (VB2(I, J, K) - AUX * OMEGA) / AB(IC,ID)
                           ENDDO
                        ENDDO
                     ENDDO
                     DO K = NZ, 1, - 1
                        DO J = NY, 1, - 1
                           DO I = NX, 1, - 1
                              IC = (K-1) * NX * NY + (J-1) * NX + I
                              IF (IC==NC) CYCLE
                              AUX =    AB(IC,IUZ) * VB2 (I  , J  , K+1) &
                                     + AB(IC,IUY) * VB2 (I  , J+1, K  ) &
                                     + AB(IC,IUX) * VB2 (I+1, J  , K  )
                              VB2 (I, J, K) = VB2 (I, J, K) - AUX * OMEGA / AB(IC,ID)
                           ENDDO
                        ENDDO
                     ENDDO
               END SELECT
         
            ENDDO
         
         !!!--------------------------------------------------------------------------------------------
         !!! GSTRIX preconditioner
         !!!--------------------------------------------------------------------------------------------
         !CASE (NSCARC_PRECON_GSTRIX)
         !   CALL SCARC_GSTRIX_BANDED(V2, ...)
            
         !!!--------------------------------------------------------------------------------------------
         !!! FFT preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_FFT)
            
            DO NM = NMESHES_MIN, NMESHES_MAX
            
               VB1 => POINT_TO_BVECTOR(NVECTOR1, NM, NL)
               VB2 => POINT_TO_BVECTOR(NVECTOR2, NM, NL)
         
               M   => MESHES(NM)
               FFT => SCARC(NM)%PRECON(NLEVEL_MIN)%FFT
               
               FFT(1:M%IBAR, 1:M%JBAR, 1:M%KBAR) = VB1(1:M%IBAR, 1:M%JBAR, 1:M%KBAR)
               SELECT CASE (TYPE_DIMENSION)
                  CASE (NSCARC_DIMENSION_TWO)
                     CALL H2CZSS (M%BXS, M%BXF, M%BZS, M%BZF, &
                                  M%IBAR+1, FFT, M%POIS_PTB, M%SAVE1, M%WORK, M%HX)
                  CASE (NSCARC_DIMENSION_THREE)
                     CALL H3CZSS (M%BXS, M%BXF, M%BYS, M%BYF, M%BZS, M%BZF, &
                                  M%IBAR+1, M%JBAR+1, FFT, M%POIS_PTB, M%SAVE1, M%WORK, M%HX)
               END SELECT
               VB2(1:M%IBAR, 1:M%JBAR, 1:M%KBAR) = FFT(1:M%IBAR, 1:M%JBAR, 1:M%KBAR)
               
            ENDDO
                     
      END SELECT
      

   !!! ---------------------------- Compact storage technique ------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      SELECT CASE (NPRECON)
      
         !!!--------------------------------------------------------------------------------------------
         !!! Multigrid preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_MULTIGRID)
      
            CALL SCARC_METHOD_MULTIGRID (NSCARC_SCOPE_PRECON, NVECTOR2, TYPE_SMOOTH)
      
      
         !!!--------------------------------------------------------------------------------------------
         !!! Jacobi preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_JACOBI)
      
            DO NM = NMESHES_MIN, NMESHES_MAX
      
               VC2 => POINT_TO_CVECTOR(NVECTOR2, NM, NL)
         
               NC     => SCARC(NM)%COMPACT(NL)%NC
               AC     => SCARC(NM)%COMPACT(NL)%A
               AC_ROW => SCARC(NM)%COMPACT(NL)%A_ROW
      
               DO IC = 1, NC
                  VC2 (IC) = VC2 (IC) / AC (AC_ROW(IC))
               ENDDO
      
            ENDDO
         
         !!!--------------------------------------------------------------------------------------------
         !!! SSOR preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_SSOR)
         
            DO NM = NMESHES_MIN, NMESHES_MAX
            
               VC2 => POINT_TO_CVECTOR(NVECTOR2, NM, NL)
         
               NC     => SCARC(NM)%COMPACT(NL)%NC
               AC     => SCARC(NM)%COMPACT(NL)%A
               AC_ROW => SCARC(NM)%COMPACT(NL)%A_ROW
               AC_COL => SCARC(NM)%COMPACT(NL)%A_COL

               !!! use only matrix superdiagonals
               FORWARD_CELL_LOOP: DO IC = 1, NC

                  AUX = 0.0_EB
                  LOWER_DIAG_LOOP: DO ICOL = AC_ROW(IC)+1, AC_ROW(IC+1)-1
                     IF (AC_COL(ICOL) >= IC) CYCLE LOWER_DIAG_LOOP
                     IF (AC_COL(ICOL) <= NC) AUX = AUX + AC(ICOL) * VC2(AC_COL(ICOL))
                  ENDDO LOWER_DIAG_LOOP
                  VC2(IC) = (VC2(IC) - AUX * OMEGA) / AC(AC_ROW(IC))
               
               ENDDO FORWARD_CELL_LOOP
               
               !!! use only matrix subdiagonals
               BACKWARD_CELL_LOOP: DO IC = NC-1, 1, -1
                  
                  AUX = 0.0_EB
                  UPPER_DIAG_LOOP: DO ICOL = AC_ROW(IC)+1, AC_ROW(IC+1)-1
                     IF (AC_COL(ICOL) <= IC) CYCLE UPPER_DIAG_LOOP
                     IF (AC_COL(ICOL) <= NC) AUX = AUX + AC(ICOL) * VC2(AC_COL(ICOL))
                  ENDDO UPPER_DIAG_LOOP
                  VC2(IC) = VC2(IC) - AUX * OMEGA / AC(AC_ROW(IC))

               ENDDO BACKWARD_CELL_LOOP
         
            ENDDO
            
         !!!--------------------------------------------------------------------------------------------
         !!! GSTRIX preconditioner
         !!!--------------------------------------------------------------------------------------------
         !CASE (NSCARC_PRECON_GSTRIX)
         !   CALL SCARC_GSTRIX_BANDED(V2, ...)
            
         !!!--------------------------------------------------------------------------------------------
         !!! FFT preconditioner
         !!!--------------------------------------------------------------------------------------------
         CASE (NSCARC_PRECON_FFT)
            
            DO NM = NMESHES_MIN, NMESHES_MAX
            
               VC1 => POINT_TO_CVECTOR(NVECTOR1, NM, NL)
               VC2 => POINT_TO_CVECTOR(NVECTOR2, NM, NL)
         
               M   => MESHES(NM)
               FFT => SCARC(NM)%PRECON(NLEVEL_MIN)%FFT
               
               DO K = 1, M%KBAR
                  DO J = 1, M%JBAR
                     DO I = 1, M%IBAR
                        IC = (K-1) * M%IBAR * M%JBAR + (J-1) * M%IBAR + I
                        FFT(I, J, K) = VC1(IC)
                     ENDDO
                  ENDDO
               ENDDO
               SELECT CASE (TYPE_DIMENSION)
                  CASE (NSCARC_DIMENSION_TWO)
                     CALL H2CZSS (M%BXS, M%BXF, M%BZS, M%BZF,&
                                  M%IBAR+1, FFT, M%POIS_PTB, M%SAVE1, M%WORK, M%HX)
                  CASE (NSCARC_DIMENSION_THREE)
                     CALL H3CZSS (M%BXS, M%BXF, M%BYS, M%BYF, M%BZS, M%BZF, &
                                  M%IBAR+1, M%JBAR+1, FFT, M%POIS_PTB, M%SAVE1, M%WORK, M%HX)
               END SELECT
               DO K = 1, M%KBAR
                  DO J = 1, M%JBAR
                     DO I = 1, M%IBAR
                        IC = (K-1) * M%IBAR * M%JBAR + (J-1) * M%IBAR + I
                        VC2(IC) = FFT(I, J, K)
                     ENDDO
                  ENDDO
               ENDDO
      
            ENDDO
      
      END SELECT

END SELECT

END SUBROUTINE SCARC_PRECONDITIONING 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Save and reset settings of calling parent-routine
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SAVE_PARENT(PARENT)
TYPE (SCARC_PARENT_TYPE), INTENT(OUT):: PARENT
PARENT%TYPE_METHOD   = TYPE_METHOD
PARENT%TYPE_SCOPE    = TYPE_SCOPE 
PARENT%TYPE_PRECON   = TYPE_PRECON
PARENT%TYPE_SMOOTH   = TYPE_SMOOTH
PARENT%TYPE_SYSTEM   = TYPE_SYSTEM
PARENT%TYPE_CYCLE    = TYPE_CYCLE 
PARENT%TYPE_ACCURACY = TYPE_ACCURACY
END SUBROUTINE SCARC_SAVE_PARENT


SUBROUTINE SCARC_RESET_PARENT(PARENT)
TYPE (SCARC_PARENT_TYPE), INTENT(IN):: PARENT
IF (TYPE_METHOD==NSCARC_METHOD_KRYLOV.AND.TYPE_SCOPE==NSCARC_SCOPE_MAIN) THEN
   TYPE_METHOD = TYPE_METHOD0
   TYPE_PRECON = TYPE_PRECON0
   TYPE_SCOPE  = TYPE_SCOPE0
ELSE
   TYPE_METHOD = PARENT%TYPE_METHOD 
   TYPE_PRECON = PARENT%TYPE_PRECON
   TYPE_SCOPE  = PARENT%TYPE_SCOPE 
ENDIF
TYPE_SMOOTH   = PARENT%TYPE_SMOOTH
TYPE_SYSTEM   = PARENT%TYPE_SYSTEM
TYPE_CYCLE    = PARENT%TYPE_CYCLE 
TYPE_ACCURACY = PARENT%TYPE_ACCURACY
END SUBROUTINE SCARC_RESET_PARENT


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform global CG-method based on global possion-matrix
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_METHOD_CG(NSCOPE, NVECTOR, NPRECON)
INTEGER, INTENT(IN) :: NSCOPE, NVECTOR, NPRECON
INTEGER   :: NL 
INTEGER   :: ISTATE, ITE
REAL (EB) :: SIGMA0, SIGMA1, ALPHA0, GAMMA0
REAL (EB) :: TNOW_KRYLOV
TYPE (SCARC_SCOPE_TYPE) :: CG
TYPE (SCARC_PARENT_TYPE) :: PARENT

TNOW_KRYLOV = SECOND()

!!!----------------------------------------------------------------------------------------------------
!!! Initialization:
!!!   - Set environment variables and define working level
!!!   - Initialize solution, right hand side vector and auxiliary vectors
!!!   - Define iterations parameters
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_SAVE_PARENT(PARENT)
CALL SCARC_SETUP_SCOPE(CG, NSCOPE, NPRECON, NVECTOR, NL)
CALL SCARC_SETUP_SOLVER(NL)

!!!----------------------------------------------------------------------------------------------------
!!! Compute initial residual and perform initial preconditioning
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_MATVEC_PRODUCT (CG%X, CG%W, NL)                                !  W := A*X
CALL SCARC_VECTOR_SUM     (CG%F, CG%W, -1.0_EB, 1.0_EB, NL)               !  W := W - F

CALL SCARC_DEBUG_LEVEL (CG%X, 'SCARC_METHOD_CG', 'X INIT', NL)
CALL SCARC_DEBUG_LEVEL (CG%F, 'SCARC_METHOD_CG', 'F INIT', NL)
CALL SCARC_DEBUG_LEVEL (CG%W, 'SCARC_METHOD_CG', 'W INIT', NL)

CG%RESIN = SCARC_L2NORM (CG%W, NL)                                        !  RESIN := ||W||

CALL SCARC_CONVERGENCE_INFO(CG%RESIN, 0, NL, CG%CROUTINE)
CALL SCARC_VECTOR_COPY     (CG%W, CG%G, 1.0_EB, NL)                       !  G := W
CALL SCARC_PRECONDITIONING (CG%W, CG%G, NL, NSCOPE)                       !  G := PRECON(W)

SIGMA0 = SCARC_SCALAR_PRODUCT(CG%W, CG%G, NL)                             !  SIGMA0 := (W,G)

CALL SCARC_DEBUG_LEVEL (CG%G, 'SCARC_METHOD_CG', 'G PRECON INIT', NL)

CALL SCARC_VECTOR_COPY (CG%G, CG%D, -1.0_EB, NL)                          !  D := -G

!!!----------------------------------------------------------------------------------------------------
!!! Perform conjugate gradient looping
!!!----------------------------------------------------------------------------------------------------
CG_LOOP: DO ITE = 1, CG%NIT
 
   CALL SCARC_MATVEC_PRODUCT (CG%D, CG%Y, NL)                             !  Y := A*D

CALL SCARC_DEBUG_LEVEL (CG%Y, 'SCARC_METHOD_CG', 'Y LOOP', NL)

   ALPHA0 = SCARC_SCALAR_PRODUCT (CG%D, CG%Y, NL)                         !  ALPHA0 := (D,Y)
   ALPHA0 = SIGMA0/ALPHA0                                                 

   CALL SCARC_VECTOR_SUM (CG%D, CG%X, ALPHA0, 1.0_EB, NL)                 !  X := ALPHA0*D + X
   CALL SCARC_VECTOR_SUM (CG%Y, CG%W, ALPHA0, 1.0_EB, NL)                 !  W := ALPHA0*Y + W

CALL SCARC_DEBUG_LEVEL (CG%D, 'SCARC_METHOD_CG', 'D LOOP', NL)
CALL SCARC_DEBUG_LEVEL (CG%X, 'SCARC_METHOD_CG', 'X LOOP', NL)
CALL SCARC_DEBUG_LEVEL (CG%W, 'SCARC_METHOD_CG', 'W LOOP', NL)

   CG%RES = SCARC_L2NORM (CG%W, NL)                                       !  RES := ||W||
   ISTATE = SCARC_CONVERGENCE_STATE (CG, ITE, NL)                         !  RES < TOL ??
   IF (ISTATE /= NSCARC_STATE_PROCEED) EXIT CG_LOOP
!IF (TYPE_DEBUG >=NSCARC_DEBUG_NONE.AND.MYID==0) &
!   WRITE(0,'(a,i3,a,e14.5,a,e14.5)') ' MG-Iteration  =',ITE,': Residuum=',SCARC_RESIDUAL

 
   CALL SCARC_VECTOR_COPY     (CG%W, CG%G, 1.0_EB, NL)                    !  G := W
   CALL SCARC_PRECONDITIONING (CG%W, CG%G, NL, NSCOPE)                    !  G := PRECON(W)

CALL SCARC_DEBUG_LEVEL (CG%G, 'SCARC_METHOD_CG', 'G PRECON ', NL)
   SIGMA1 = SCARC_SCALAR_PRODUCT (CG%W, CG%G, NL)                         !  SIGMA1 := (W,G)
   GAMMA0 = SIGMA1/SIGMA0                                                   
   SIGMA0 = SIGMA1                                                         

   CALL SCARC_VECTOR_SUM (CG%G, CG%D, -1.0_EB, GAMMA0, NL)                !  D := -G + GAMMA0*D

ENDDO CG_LOOP
 
!!!----------------------------------------------------------------------------------------------------
!!! Determine convergence rate and print corresponding information
!!! In case of CG as main solver:
!!!   - Transfer ScaRC solution vector X to FDS pressure vector 
!!!   - Set ghost cell values along external boundaries
!!!   - Exchange values along internal boundaries 
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_CONVERGENCE_RATE(CG, ITE, ISTATE)
!IF (TYPE_DEBUG >=NSCARC_DEBUG_NONE.AND.MYID==0) &
!   WRITE(0,'(a,e14.5)') '                                        ---->  Konvergenzrate=',SCARC_CAPPA


IF (TYPE_SCOPE == NSCARC_SCOPE_MAIN) THEN
   CALL SCARC_FINISH_SOLVER  (NLEVEL_MIN)
   CALL SCARC_UPDATE_GHOSTCELLS (NLEVEL_MIN)
!ELSE IF (TYPE_SCOPE == NSCARC_SCOPE_COARSE) THEN
!   CALL SCARC_VECTOR_COPY (CG%X, CG%F, 1.0_EB, NL)                         
ENDIF

CALL SCARC_DEBUG_LEVEL (CG%X, 'SCARC_METHOD_CG', 'X FINAL', NL)
CALL SCARC_DEBUG_LEVEL (CG%F, 'SCARC_METHOD_CG', 'F FINAL', NL)
CALL SCARC_RESET_PARENT(PARENT)

TUSED_SCARC(NSCARC_TIME_KRYLOV,:)=TUSED_SCARC(NSCARC_TIME_KRYLOV,:)+SECOND()-TNOW_KRYLOV
TUSED_SCARC(NSCARC_TIME_TOTAL ,:)=TUSED_SCARC(NSCARC_TIME_TOTAL ,:)+SECOND()-TNOW_KRYLOV
END SUBROUTINE SCARC_METHOD_CG


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform global BICGstab-method based on global possion-matrix - banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_METHOD_BICG(NSCOPE, NVECTOR, NPRECON)
INTEGER, INTENT(IN) :: NSCOPE, NVECTOR, NPRECON
INTEGER   :: NL = NSCARC_LEVEL_NONE
INTEGER   :: ISTATE, ITE
REAL (EB) :: ALPHA0, ALPHA1, ALPHA2, RHO0, RHO1, DTHETA, DBETA
REAL (EB) :: TNOW_KRYLOV
TYPE (SCARC_SCOPE_TYPE)  :: BICG
TYPE (SCARC_PARENT_TYPE) :: PARENT

TNOW_KRYLOV = SECOND()

!!!----------------------------------------------------------------------------------------------------
!!! Initialization
!!!   - Set environment variables and define working level
!!!   - Initialize solution, right hand side vector and auxiliary vectors
!!!   - Define iterations parameters
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_SAVE_PARENT(PARENT)
CALL SCARC_SETUP_SCOPE(BICG, NSCOPE, NPRECON, NVECTOR, NL)
CALL SCARC_SETUP_SOLVER(NL)
   
!!!----------------------------------------------------------------------------------------------------
!!! Compute initial defect and perform (double) initial preconditioning
!!!----------------------------------------------------------------------------------------------------
ALPHA0 = 1.0_EB
RHO0   = 1.0_EB
RHO1   = 0.0_EB
DBETA  = 0.0_EB
DTHETA = 1.0_EB
 
!CALL SCARC_VECTOR_COPY    (BICG%F, BICG%W, 1.0_EB, NL)                         !  W := F
!CALL SCARC_PRECONDITIONING (BICG%W, BICG%W, NL, NSCOPE)                        !  W := PRECON(W)
CALL SCARC_MATVEC_PRODUCT  (BICG%X, BICG%W, NL)                                 !  W := A*X
CALL SCARC_VECTOR_SUM      (BICG%F, BICG%W, 1.0_EB, -1.0_EB, NL)                !  W := F - W
CALL SCARC_PRECONDITIONING (BICG%W, BICG%W, NL, NSCOPE)                         !  W := PRECON(W)

BICG%RESIN = SCARC_L2NORM (BICG%W, NL)                                          !  RESIN := ||W||
CALL SCARC_CONVERGENCE_INFO (BICG%RESIN, 0, NL, BICG%CROUTINE)

CALL SCARC_VECTOR_COPY (BICG%W, BICG%G, 1.0_EB, NL)                             !  G := W
   
!!!----------------------------------------------------------------------------------------------------
!!! Perform bi-conjugate gradient looping:
!!!----------------------------------------------------------------------------------------------------
BICG_LOOP: DO ITE = 1, BICG%NIT

   RHO1  = SCARC_SCALAR_PRODUCT (BICG%G, BICG%W, NL)                            ! RHO1 := (G,W)
   DBETA = (RHO1*DTHETA)/(RHO0*ALPHA0)                                     
   RHO0  = RHO1

   CALL SCARC_VECTOR_SUM      (BICG%W, BICG%Z, 1.0_EB       , DBETA , NL)       ! Z := W + DBETA*Z
   CALL SCARC_VECTOR_SUM      (BICG%Y, BICG%Z, -DBETA*ALPHA0, 1.0_EB, NL)       ! Z := -DBETA*ALPHA0*Y + Z
   CALL SCARC_MATVEC_PRODUCT  (BICG%Z, BICG%Y, NL)                              ! Y := A*Z
   CALL SCARC_PRECONDITIONING (BICG%Y, BICG%Y, NL, NSCOPE)                      ! Z := PRECON(Z)

   DTHETA = SCARC_SCALAR_PRODUCT (BICG%G, BICG%Y, NL)                           ! DTHETA := (G,Y)
   DTHETA = RHO1/DTHETA

   CALL SCARC_VECTOR_SUM      (BICG%Y, BICG%W, -DTHETA, 1.0_EB, NL)             ! W := -DTHETA*Y + W
   CALL SCARC_MATVEC_PRODUCT  (BICG%W, BICG%D, NL)                              ! D := A*W
   CALL SCARC_PRECONDITIONING (BICG%D, BICG%D, NL, NSCOPE)                      ! D := PRECON(D)
   
   ALPHA1 = SCARC_SCALAR_PRODUCT (BICG%D, BICG%W, NL)                           ! ALPHA1 := (D,W)
   ALPHA2 = SCARC_SCALAR_PRODUCT (BICG%D, BICG%D, NL)                           ! ALPHA2 := (D,D)
   ALPHA0 = ALPHA1/ALPHA2

   CALL SCARC_VECTOR_SUM (BICG%Z, BICG%X,  DTHETA, 1.0_EB, NL)                  ! X :=  DTHETA*Z + X
   CALL SCARC_VECTOR_SUM (BICG%W, BICG%X,  ALPHA0, 1.0_EB, NL)                  ! X :=  ALPHA0*W + X
   CALL SCARC_VECTOR_SUM (BICG%D, BICG%W, -ALPHA0, 1.0_EB, NL)                  ! W := -ALPHA0*D + W

   BICG%RES = SCARC_L2NORM (BICG%W, NL)                                         ! RES := ||W||

   ISTATE = SCARC_CONVERGENCE_STATE(BICG, ITE, NL)                              ! RES < TOL ???
   IF (ISTATE /= NSCARC_STATE_PROCEED) EXIT BICG_LOOP
 
ENDDO BICG_LOOP

!!!----------------------------------------------------------------------------------------------------
!!! Determine convergence rate and print corresponding information
!!! In case of BICG as main solver:
!!!   - Transfer ScaRC solution vector X to FDS pressure vector 
!!!   - Set ghost cell values along external boundaries
!!!   - Exchange values along internal boundaries 
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_CONVERGENCE_RATE(BICG, ITE, ISTATE)

IF (TYPE_SCOPE == NSCARC_SCOPE_MAIN) THEN
   CALL SCARC_FINISH_SOLVER(NLEVEL_MIN)
   CALL SCARC_UPDATE_GHOSTCELLS(NLEVEL_MIN)
!ELSE IF (TYPE_SCOPE == NSCARC_SCOPE_COARSE) THEN
!   CALL SCARC_VECTOR_COPY (BICG%X, BICG%F, 1.0_EB, NL)                         
ENDIF
CALL SCARC_RESET_PARENT(PARENT)

TUSED_SCARC(NSCARC_TIME_KRYLOV,:)=TUSED_SCARC(NSCARC_TIME_KRYLOV,:)+SECOND()-TNOW_KRYLOV
TUSED_SCARC(NSCARC_TIME_TOTAL ,:)=TUSED_SCARC(NSCARC_TIME_TOTAL ,:)+SECOND()-TNOW_KRYLOV
END SUBROUTINE SCARC_METHOD_BICG


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform geometric multigrid method based on global possion-matrix
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_METHOD_MULTIGRID(NSCOPE, NVECTOR, NPRECON)
INTEGER, INTENT(IN) :: NSCOPE, NVECTOR, NPRECON
INTEGER   :: NL = NSCARC_LEVEL_NONE
INTEGER   :: ISTATE, ICYCLE, ITE
REAL (EB) :: TNOW_MULTIGRID
TYPE (SCARC_SCOPE_TYPE)  :: MG
TYPE (SCARC_PARENT_TYPE) :: PARENT

TNOW_MULTIGRID = SECOND()

!!!----------------------------------------------------------------------------------------------------
!!! Initialization:
!!!   - Set environment variables and define working level
!!!   - Initialize solution, right hand side vector 
!!!   - Define iterations parameters (NL is set to finest level)
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_SAVE_PARENT(PARENT)
CALL SCARC_SETUP_SCOPE(MG, NSCOPE, NPRECON, NVECTOR, NL)
CALL SCARC_SETUP_SOLVER(NL)


!!!----------------------------------------------------------------------------------------------------
!!! Compute initial defect:  RESIN := || F - A*X ||
!!!   - Initialize cycle counts for MG-iteration
!!!   - Perform initial matrix-vector product on finest level
!!!   - calculate norm of initial residual on finest level
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_MATVEC_PRODUCT (MG%X, MG%D, NL)                                       !  D := A*X
CALL SCARC_VECTOR_SUM     (MG%F, MG%D, 1.0_EB, -1.0_EB, NL)                      !  D := F - D 

ICYCLE = SCARC_CYCLE_CONTROL(NSCARC_CYCLE_SETUP, NL)
MG%RESIN = SCARC_L2NORM (MG%D, NL)                                               !  RESIN := ||D||

CALL SCARC_CONVERGENCE_INFO(MG%RESIN, 0, NL, MG%CROUTINE)

!!!----------------------------------------------------------------------------------------------------

!!! Perform multigrid-looping (start each iteration on finest level) 
!!!----------------------------------------------------------------------------------------------------
MULTIGRID_LOOP: DO ITE = 1, MG%NIT
 
   NL = NLEVEL_MIN
   ICYCLE = SCARC_CYCLE_CONTROL(NSCARC_CYCLE_RESET, NL)

   CYCLE_LOOP: DO WHILE (ICYCLE /= NSCARC_CYCLE_EXIT)

      !!! presmoothing  (smoothing/restriction till coarsest level is reached)
      PRESMOOTHING_LOOP: DO WHILE (NL < NLEVEL_MAX)
         CALL SCARC_SMOOTHING    (MG, NSCARC_CYCLE_PRESMOOTH, NL, NSCOPE)        ! D_fine   := smooth(defect)
         CALL SCARC_RESTRICTION  (MG%D, MG%F, NL, NL+1)                          ! F_coarse := rest(D_fine)
         CALL SCARC_VECTOR_CLEAR (MG%X, NL+1)                                    ! X_coarse := 0.0
         NL = NL + 1                                                             ! set coarser level
      ENDDO PRESMOOTHING_LOOP

      !!! coarse grid solver
      SELECT CASE (TYPE_COARSE)
         CASE (NSCARC_COARSE_ITERATIVE)
            CALL SCARC_METHOD_CG (NSCARC_SCOPE_COARSE, MG%F, NSCARC_PRECON_SSOR) ! X_coarse := exact_sol(.)
         CASE (NSCARC_COARSE_DIRECT)
            CALL SCARC_METHOD_GE (MG%X, MG%F)
      END SELECT

      !!! postsmoothing (smoothing/restriction till finest level is reached again)
      POSTSMOOTHING_LOOP: DO WHILE (NL > NLEVEL_MIN) 
         NL=NL-1
         CALL SCARC_PROLONGATION (MG%X, MG%D, NL+1, NL)                          ! D_fine := prol(X_coarse)
         CALL SCARC_VECTOR_SUM   (MG%D, MG%X, 1.0_EB, 1.0_EB, NL)                ! X_fine := D_fine + X_fine
         CALL SCARC_SMOOTHING    (MG, NSCARC_CYCLE_POSTSMOOTH, NL, NSCOPE)       ! D_fine := smooth(defect)
         ICYCLE = SCARC_CYCLE_CONTROL(NSCARC_CYCLE_PROCEED, NL)                  ! perform requested cycle
         IF (ICYCLE /= NSCARC_CYCLE_POSTSMOOTH) CYCLE CYCLE_LOOP
      ENDDO POSTSMOOTHING_LOOP

   ENDDO CYCLE_LOOP

   IF (NL /= NLEVEL_MIN) THEN
      WRITE(*,*) 'ERROR in SCARC_MULTIGRID, wrong level ', NL
      STOP
   ENDIF

   !!!-------------------------------------------------------------------------------------------------
   !!! Compute norm of new residual on finest level and  leave loop correspondingly
   !!!-------------------------------------------------------------------------------------------------
   CALL SCARC_MATVEC_PRODUCT (MG%X, MG%D, NL)                                    ! D := A*X
   CALL SCARC_VECTOR_SUM     (MG%F, MG%D, 1.0_EB, -1.0_EB, NL)                   ! D := F - D

   MG%RES = SCARC_L2NORM (MG%D, NL)                                              ! RES := ||D||
   ISTATE = SCARC_CONVERGENCE_STATE(MG, ITE, NL)                                 ! convergence ?
   IF (ISTATE /= NSCARC_STATE_PROCEED) EXIT MULTIGRID_LOOP
 
ENDDO MULTIGRID_LOOP

!!!----------------------------------------------------------------------------------------------------
!!! Determine convergence rate and print corresponding information
!!! In case of MG as main solver:
!!!   - Transfer ScaRC solution vector X to FDS pressure vector 
!!!   - Set ghost cell values along external boundaries 
!!!   - Exchange values along internal boundaries (consistency!)
!!!----------------------------------------------------------------------------------------------------
CALL SCARC_CONVERGENCE_RATE(MG, ITE, ISTATE)

SELECT CASE (TYPE_SCOPE)
   CASE (NSCARC_SCOPE_MAIN)
      CALL SCARC_FINISH_SOLVER(NLEVEL_MIN)
      CALL SCARC_UPDATE_GHOSTCELLS(NLEVEL_MIN)
   CASE (NSCARC_SCOPE_PRECON)
      CALL SCARC_VECTOR_COPY(MG%X, MG%F, 1.0_EB, NLEVEL_MIN)
END SELECT

!CALL SCARC_DEBUG_LEVEL (MG%X, 'SCARC_METHOD_MULTIGRID', 'X FINAL', NLEVEL_MIN)
!CALL SCARC_DEBUG_LEVEL (MG%F, 'SCARC_METHOD_MULTIGRID', 'F FINAL', NLEVEL_MIN)
CALL SCARC_RESET_PARENT(PARENT)

TUSED_SCARC(NSCARC_TIME_MULTIGRID,:)=TUSED_SCARC(NSCARC_TIME_MULTIGRID,:)+SECOND()-TNOW_MULTIGRID
TUSED_SCARC(NSCARC_TIME_TOTAL    ,:)=TUSED_SCARC(NSCARC_TIME_TOTAL    ,:)+SECOND()-TNOW_MULTIGRID
END SUBROUTINE SCARC_METHOD_MULTIGRID


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Control multigrid cycling (F/V/W)
!!! Note: NLEVEL_MIN corresponds to finest level, NLEVEL_MAX to coarsest level
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
INTEGER FUNCTION SCARC_CYCLE_CONTROL(NSCOPE, NL)
INTEGER, INTENT(IN) :: NSCOPE, NL
INTEGER :: NM, NL0, ICYCLE

SELECT CASE (NSCOPE)

   !!!-------------------------------------------------------------------------------------------------
   !!! initialize cycle counts at beginning of multigrid method
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_CYCLE_SETUP)

      DO NM = NMESHES_MIN, NMESHES_MAX
         SCARC(NM)%CYCLE_COUNT(2,NL)=1
         DO NL0 = NLEVEL_MIN+1, NLEVEL_MAX - 1
            IF (TYPE_CYCLE==NSCARC_CYCLE_F) THEN
               SCARC(NM)%CYCLE_COUNT(2,NL0)=2
            ELSE
               SCARC(NM)%CYCLE_COUNT(2,NL0)=TYPE_CYCLE
            ENDIF
         ENDDO
      ENDDO

      ICYCLE = NSCARC_CYCLE_NEXT
      
   !!!-------------------------------------------------------------------------------------------------
   !!! reset cycle counts at beginning of each new multigrid iteration
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_CYCLE_RESET)

      DO NM = NMESHES_MIN, NMESHES_MAX
         DO NL0 = NLEVEL_MIN, NLEVEL_MAX
            SCARC(NM)%CYCLE_COUNT(1,NL0)=SCARC(NM)%CYCLE_COUNT(2,NL0)
         ENDDO
      ENDDO
      ICYCLE = NSCARC_CYCLE_NEXT

   !!!-------------------------------------------------------------------------------------------------
   !!! determine where to proceed with cycling
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_CYCLE_PROCEED)

      DO NM = NMESHES_MIN, NMESHES_MAX

         SCARC(NM)%CYCLE_COUNT(1,NL)=SCARC(NM)%CYCLE_COUNT(1,NL)-1

         IF (SCARC(NM)%CYCLE_COUNT(1,NL)==0) THEN
            IF (TYPE_CYCLE==NSCARC_CYCLE_F) THEN
               SCARC(NM)%CYCLE_COUNT(1,NL)=1
            ELSE
               SCARC(NM)%CYCLE_COUNT(1,NL)=SCARC(NM)%CYCLE_COUNT(2,NL)
            ENDIF
            IF (NL == NLEVEL_MIN) THEN
               ICYCLE = NSCARC_CYCLE_EXIT
            ELSE
               ICYCLE = NSCARC_CYCLE_POSTSMOOTH
            ENDIF
         ELSE
            IF (NL == NLEVEL_MIN) THEN
               ICYCLE = NSCARC_CYCLE_EXIT
            ELSE
               ICYCLE = NSCARC_CYCLE_NEXT
            ENDIF
         ENDIF

      ENDDO

END SELECT

SCARC_CYCLE_CONTROL = ICYCLE
RETURN

END FUNCTION SCARC_CYCLE_CONTROL


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform smoothing - banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SMOOTHING(MG, NTYPE, NL, NSCOPE)
INTEGER , INTENT(IN) :: NTYPE, NL, NSCOPE
TYPE (SCARC_SCOPE_TYPE), INTENT(INOUT) :: MG
INTEGER :: ITE, ISTATE
REAL(EB):: TNOW_SMOOTH
LOGICAL :: BMATVEC, BL2NORM
TYPE (SCARC_SCOPE_TYPE) :: SM

TNOW_SMOOTH = SECOND()

!!!----------------------------------------------------------------------------------------------------
!!! Initialization
!!!----------------------------------------------------------------------------------------------------
SM%X = MG%X
SM%F = MG%F
SM%D = MG%D

SELECT CASE (NTYPE)
   CASE (NSCARC_CYCLE_PRESMOOTH)
      SM%CROUTINE = 'SCARC_PRESMOOTHER'
   CASE (NSCARC_CYCLE_POSTSMOOTH)
      SM%CROUTINE = 'SCARC_POSTSMOOTHER'
END SELECT
SM%NIT   = SCARC_SMOOTH_ITERATIONS
SM%EPS   = SCARC_SMOOTH_ACCURACY
SM%OMEGA = SCARC_SMOOTH_OMEGA

BL2NORM  = .TRUE.
IF (NTYPE == NSCARC_CYCLE_PRESMOOTH.AND.NL==1) THEN
   BMATVEC = .FALSE.
ELSE
   BMATVEC = .TRUE.
ENDIF
BMATVEC = .TRUE.
BL2NORM = .TRUE.

!!!----------------------------------------------------------------------------------------------------
!!! Calculate initial defect on level NL (only if BMATVEC = .TRUE.)
!!! Because initial vector is set to zero, this defect corresponds to F
!!!----------------------------------------------------------------------------------------------------
IF (BMATVEC) THEN
   CALL SCARC_MATVEC_PRODUCT (SM%X, SM%D, NL)                                  !  D := A*X
   CALL SCARC_VECTOR_SUM     (SM%F, SM%D, 1.0_EB, -1.0_EB, NL)                 !  D := F - D
ENDIF

IF (BL2NORM.AND.BMATVEC) THEN
   SM%RESIN = SCARC_L2NORM (SM%D, NL)                                          !  RESIN := ||D||
ELSE
   SM%RESIN = SCARC_RESIDUAL
ENDIF

!!!----------------------------------------------------------------------------------------------------
!!! Smoothing loop
!!!----------------------------------------------------------------------------------------------------
SMOOTH_LOOP: DO ITE=1, SM%NIT
 
   CALL SCARC_PRECONDITIONING (SM%D, SM%D, NL, NSCOPE)                         !  D := PRECON (D)
   CALL SCARC_VECTOR_SUM      (SM%D, SM%X, SM%OMEGA, 1.0_EB, NL)               !  X := OMEGA*D + X
   CALL SCARC_MATVEC_PRODUCT  (SM%X, SM%D, NL)                                 !  D := A*X
   CALL SCARC_VECTOR_SUM      (SM%F, SM%D, 1.0_EB, -1.0_EB, NL)                !  D := F - D

   IF (BL2NORM.OR.ITE==SM%NIT) THEN
      SM%RES = SCARC_L2NORM (SM%D, NL)                                         !  RES := ||D||
!WRITE(SCARC_LU,*) 'SMOOTHER RESIDUUM =',SM%RES
      ISTATE = SCARC_CONVERGENCE_STATE(SM, ITE, NL)
      IF (ISTATE /= NSCARC_STATE_PROCEED) EXIT SMOOTH_LOOP                     !  RES < TOL ?
   ENDIF
!WRITE(SCARC_LU,*) 'SMOOTHER LOOP ', ITE,': RESIDUAL =',SM%RES, BL2NORM

ENDDO SMOOTH_LOOP

!!!----------------------------------------------------------------------------------------------------
!!! Determine convergence rate and print corresponding information
!!!----------------------------------------------------------------------------------------------------
IF (BL2NORM) CALL SCARC_CONVERGENCE_RATE(SM, ITE, NL)

TUSED_SCARC(NSCARC_TIME_SMOOTH,:)=TUSED_SCARC(NSCARC_TIME_SMOOTH,:)+SECOND()-TNOW_SMOOTH
TUSED_SCARC(NSCARC_TIME_TOTAL ,:)=TUSED_SCARC(NSCARC_TIME_TOTAL ,:)+SECOND()-TNOW_SMOOTH
END SUBROUTINE SCARC_SMOOTHING


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Gaussian elimination for coarse grid solution
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_METHOD_GE(NVECTORX, NVECTORF)
INTEGER, INTENT(IN) :: NVECTORX, NVECTORF
INTEGER :: NM, IC, IX, IY, IZ, IOFFSET, IERR, DISP
REAL(EB), POINTER, DIMENSION(:,:,:) :: VBX, VBF
REAL(EB), POINTER, DIMENSION(:)     :: VCX, VCF
REAL (EB) :: TNOW_COARSE
TYPE (SCARC_TYPE), POINTER :: SM
TYPE (SCARC_BANDED_TYPE),  POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

TNOW_COARSE = SECOND()

IERR=0
SM => SCARC(NMASTER)

!!!----------------------------------------------------------------------------------------------------
!!! Parallel version
!!!----------------------------------------------------------------------------------------------------
IF (USE_MPI) THEN

   DO NM = 1, NMESHES
      SM%COUNTS1(NM-1) = NC_COARSE(NM)
      SM%DISPLS1(NM-1) = SM%OFFSET(NM)
   ENDDO

   DO NM = NMESHES_MIN, NMESHES_MAX
   
      SELECT CASE (TYPE_SYSTEM)
   
         CASE (NSCARC_SYSTEM_BANDED)
   
            SB  => SCARC(NM)%BANDED(NLEVEL_MAX)
            VBF => POINT_TO_BVECTOR (NVECTORF, NM, NLEVEL_MAX)
   
            IOFFSET = SM%OFFSET(NM)
   
            DISP = SM%DISPLS1(MYID)+1
            SELECT CASE (TYPE_DIMENSION)
   
               CASE (NSCARC_DIMENSION_TWO)
   
                  DO IZ = 1, SB%NZ
                     DO IX = 1, SB%NX
                        IC = (IZ-1)*SB%NX + IX + IOFFSET
                        SM%X_BUF (DISP) = VBF(IX, 1, IZ)
                        DISP = DISP + 1
                     ENDDO
                  ENDDO
   
               CASE (NSCARC_DIMENSION_THREE)
   
                  DO IZ = 1, SB%NZ
                     DO IY = 1, SB%NY
                        DO IX = 1, SB%NX
                           IC = (IZ-1)*SB%NX*SB%NY + (IY-1)*SB%NX + IX + IOFFSET
                           SM%X_BUF (DISP) = VBF(IX, IY, IZ)
                           DISP = DISP + 1
                        ENDDO
                     ENDDO
                  ENDDO
   
            END SELECT

            DISP = SM%DISPLS1(MYID)+1
            CALL MPI_ALLGATHERV(SM%X_BUF(DISP),SM%COUNTS1(MYID),MPI_DOUBLE_PRECISION, &
                                SM%X_COARSE,SM%COUNTS1,SM%DISPLS1,MPI_DOUBLE_PRECISION,MPI_COMM_WORLD,IERR)

         CASE (NSCARC_SYSTEM_COMPACT)
   
            SC => SCARC(NM)%COMPACT(NLEVEL_MAX)
            IOFFSET = SM%OFFSET(NM)
   
            DO IC = 1, SC%NZ
               SM%X_COARSE (IC) = VCF(IC)
            ENDDO
   
            WRITE(*,*) 'SCARC_METHOD_GE, COMPACT, NOT FINISHED YET'
            STOP
      END SELECT
   
   ENDDO
   
   WRITE(*,*) 'STILL MKL VERSION !!'
   !IF (MYID+1 == NMASTER) THEN
   !   CALL DGETRS('N', NC_COARSE0, 1, SM%A_COARSE, NC_COARSE0, SM%PIVOT, &
   !               SM%X_COARSE, NC_COARSE0, IERR)
   !ENDIF
   
   DO NM = NMESHES_MIN, NMESHES_MAX
   
      SELECT CASE (TYPE_SYSTEM)
   
         CASE (NSCARC_SYSTEM_BANDED)
   
            SB => SCARC(NM)%BANDED(NLEVEL_MAX)
            IOFFSET = SM%OFFSET(NM)
   
            VBX => POINT_TO_BVECTOR (NVECTORX, NM, NLEVEL_MAX)
   
            SELECT CASE (TYPE_DIMENSION)
   
               CASE (NSCARC_DIMENSION_TWO)
   
                  DO IZ = 1, SB%NZ
                     DO IX = 1, SB%NX
                        IC = (IZ-1)*SB%NX + IX + IOFFSET
                        VBX(IX, 1, IZ) = SM%X_COARSE (IC) 
                     ENDDO
                  ENDDO
   
               CASE (NSCARC_DIMENSION_THREE)
   
                  DO IZ = 1, SB%NZ
                     DO IY = 1, SB%NY
                        DO IX = 1, SB%NX
                           IC = (IZ-1)*SB%NX*SB%NY + (IY-1)*SB%NX + IX + IOFFSET
                           VBX(IX, IY, IZ) = SM%X_COARSE (IC)  
                        ENDDO
                     ENDDO
                  ENDDO
   
            END SELECT
   
         CASE (NSCARC_SYSTEM_COMPACT)
   
            SC => SCARC(NM)%COMPACT(NLEVEL_MAX)
            IOFFSET = SM%OFFSET(NM)
   
            VBX => POINT_TO_BVECTOR (NVECTORX, NM, NLEVEL_MAX)
   
            DO IC = 1, SC%NC
               VCX(IC) = SM%X_COARSE (IC) 
            ENDDO
   
      END SELECT
   
   ENDDO

!!!----------------------------------------------------------------------------------------------------
!!! Serial version
!!!----------------------------------------------------------------------------------------------------
ELSE

   DO NM = NMESHES_MIN, NMESHES_MAX
   
      SELECT CASE (TYPE_SYSTEM)
   
         CASE (NSCARC_SYSTEM_BANDED)
   
            SB => SCARC(NM)%BANDED(NLEVEL_MAX)
   
            VBF => POINT_TO_BVECTOR (NVECTORF, NM, NLEVEL_MAX)
   
            IOFFSET = SM%OFFSET(NM)
   
            SELECT CASE (TYPE_DIMENSION)
   
               CASE (NSCARC_DIMENSION_TWO)
   
                  DO IZ = 1, SB%NZ
                     DO IX = 1, SB%NX
                           IC = (IZ-1)*SB%NX + IX + IOFFSET
                           SM%X_COARSE (IC) = VBF(IX, 1, IZ)
                     ENDDO
                  ENDDO
   
               CASE (NSCARC_DIMENSION_THREE)
   
                  DO IZ = 1, SB%NZ
                     DO IY = 1, SB%NY
                        DO IX = 1, SB%NX
                           IC = (IZ-1)*SB%NX*SB%NY + (IY-1)*SB%NX + IX + IOFFSET
                           SM%X_COARSE (IC) = VBF(IX, IY, IZ)
                        ENDDO
                     ENDDO
                  ENDDO
   
            END SELECT
   
         CASE (NSCARC_SYSTEM_COMPACT)
   
            SC => SCARC(NM)%COMPACT(NLEVEL_MAX)
            IOFFSET = SM%OFFSET(NM)
   
            DO IC = 1, SC%NZ
               SM%X_COARSE (IC) = VCF(IC)
            ENDDO
   
      END SELECT
   
   ENDDO
   
   WRITE(*,*) 'STILL MKL VERSION !!'
   !IF (MYID+1 == NMASTER) THEN
   !   CALL DGETRS('N', NC_COARSE0, 1, SM%A_COARSE, NC_COARSE0, SM%PIVOT, &
   !               SM%X_COARSE, NC_COARSE0, IERR)
   !ENDIF
   
   DO NM = NMESHES_MIN, NMESHES_MAX
   
      SELECT CASE (TYPE_SYSTEM)
   
         CASE (NSCARC_SYSTEM_BANDED)
   
            SB => SCARC(NM)%BANDED(NLEVEL_MAX)
            IOFFSET = SM%OFFSET(NM)
   
            VBX => POINT_TO_BVECTOR (NVECTORX, NM, NLEVEL_MAX)
   
            SELECT CASE (TYPE_DIMENSION)
   
               CASE (NSCARC_DIMENSION_TWO)
   
                  DO IZ = 1, SB%NZ
                     DO IX = 1, SB%NX
                        IC = (IZ-1)*SB%NX + IX + IOFFSET
                        VBX(IX, 1, IZ) = SM%X_COARSE (IC) 
                     ENDDO
                  ENDDO
   
               CASE (NSCARC_DIMENSION_THREE)
   
                  DO IZ = 1, SB%NZ
                     DO IY = 1, SB%NY
                        DO IX = 1, SB%NX
                           IC = (IZ-1)*SB%NX*SB%NY + (IY-1)*SB%NX + IX + IOFFSET
                           VBX(IX, IY, IZ) = SM%X_COARSE (IC)  
                        ENDDO
                     ENDDO
                  ENDDO
   
            END SELECT
   
         CASE (NSCARC_SYSTEM_COMPACT)
   
            SC => SCARC(NM)%COMPACT(NLEVEL_MAX)
            IOFFSET = SM%OFFSET(NM)
   
            VBX => POINT_TO_BVECTOR (NVECTORX, NM, NLEVEL_MAX)
   
            DO IC = 1, SC%NC
               VCX(IC) = SM%X_COARSE (IC) 
            ENDDO
   
      END SELECT
   
   ENDDO

ENDIF

TUSED_SCARC(NSCARC_TIME_COARSE,:)=TUSED_SCARC(NSCARC_TIME_COARSE,:)+SECOND()-TNOW_COARSE
TUSED_SCARC(NSCARC_TIME_TOTAL ,:)=TUSED_SCARC(NSCARC_TIME_TOTAL ,:)+SECOND()-TNOW_COARSE
END SUBROUTINE SCARC_METHOD_GE


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Initialize GSTRIX preconditioner/smoother
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_GSTRIX(NM, NL)
INTEGER, INTENT(IN) :: NM, NL
INTEGER :: IC, IERR
TYPE (SCARC_PRECON_TYPE), POINTER :: SP
TYPE (SCARC_BANDED_TYPE), POINTER :: SB

IERR=0

SB => SCARC(NM)%BANDED(NL)
SP => SCARC(NM)%PRECON(NL)

SELECT CASE (TYPE_DIMENSION)

   !!!----------------------------------------------------------------------------------------------------
   !!! 2D-version
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DIMENSION_TWO)

      ALLOCATE (SP%MDX(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX', 'SP%MDX', IERR)
      
      ALLOCATE (SP%UDX(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX', 'SP%UDX', IERR)
      
      ALLOCATE (SP%LDX(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX', 'SP%LDX', IERR)
      
      ALLOCATE (SP%MDZ(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX', 'SP%MDZ', IERR)
      
      ALLOCATE (SP%DWORK(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX', 'SP%DWORK', IERR)
      
      !!! save different diagonals of matrix ('D' corresponds to main, 'L' to lower, 'U' to upper)
      IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
         DO IC = 1, SB%NC
            SP%MDX(IC) = SB%A(IC,ID)         ! main  diagonal in x-direction
            SP%MDZ(IC) = SB%A(IC,ILZ)        ! main  diagonal in z-direction
            SP%LDX(IC) = SB%A(IC,ILX)        ! lower diagonal in x-direction
            SP%UDX(IC) = SB%A(IC,IUX)        ! upper diagonal in x-direction
         ENDDO
      ELSE
         WRITE(*,*) 'HIER NOCH ANPASSEN !!'
         DO IC = 1, SB%NC
   !          SP%MDX(IC) = SC%A(IC,ID)         ! main  diagonal in x-direction
   !         SP%MDZ(IC) = SC%A(IC,ILZ)        ! main  diagonal in z-direction
   !         SP%LDX(IC) = SC%A(IC,ILX)        ! lower diagonal in x-direction
   !         SP%UDX(IC) = SC%A(IC,IUX)        ! upper diagonal in x-direction
         ENDDO
      ENDIF
       
      !!! perform LU-factorization of matrix AG according to banded storage technique
      DO IC = 2, SB%NC
         SP%LDX (IC) = SP%LDX(IC) / SP%MDX(IC-1)
         SP%MDX (IC) = SP%MDX(IC) - SP%LDX(IC) * SP%UDX(IC-1)
      ENDDO
       
      !!! replace diagonal values diag(i) by 1/diag(i) and multiply UDX with 1/diag(i)
      DO IC = 1, SB%NC
         SP%MDX (IC) = 1.0_EB / SP%MDX(IC)
         SP%UDX (IC) = SP%MDX(IC) * SP%UDX(IC)
      ENDDO
      
   !!!----------------------------------------------------------------------------------------------------
   !!! 3D-version
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DIMENSION_THREE)
   
      ALLOCATE (SP%MDX(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX3D', 'SP%MDX', IERR)
      
      ALLOCATE (SP%UDX(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX3D', 'SP%UDX', IERR)
      
      ALLOCATE (SP%LDX(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX3D', 'SP%LDX', IERR)
      
      ALLOCATE (SP%MDY(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX3D', 'SP%MDY', IERR)
      
      ALLOCATE (SP%MDZ(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX3D', 'SP%MDZ', IERR)
      
      ALLOCATE (SP%DWORK(1:SB%NC), STAT=IERR)
      CALL CHKMEMERR ('SCARC_PRECON_INIT_GSTRIX3D', 'SP%DWORK', IERR)
      
      !!! save different diagonals of matrix ('D' corresponds to main, 'L' to lower, 'U' to upper)
      IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
         DO IC = 1, SB%NC
            SP%MDX(IC) = SB%A(IC,ID)        ! main  diagonal in x-direction
            SP%MDZ(IC) = SB%A(IC,ILZ)       ! main  diagonal in z-direction
            SP%MDY(IC) = SB%A(IC,ILY)       ! main  diagonal in y-direction
            SP%LDX(IC) = SB%A(IC,ILX)       ! lower diagonal in x-direction
            SP%UDX(IC) = SB%A(IC,IUX)       ! upper diagonal in x-direction
         ENDDO
      ELSE
         WRITE(*,*) 'HIER NOCH ANPASSEN !!'
         DO IC = 1, SB%NC
   !         SP%MDX(IC) = SC%A(IC,ID)        ! main  diagonal in x-direction
   !         SP%MDZ(IC) = SC%A(IC,ILZ)       ! main  diagonal in z-direction
   !         SP%MDY(IC) = SC%A(IC,ILY)       ! main  diagonal in y-direction
   !         SP%LDX(IC) = SC%A(IC,ILX)       ! lower diagonal in x-direction
   !         SP%UDX(IC) = SC%A(IC,IUX)       ! upper diagonal in x-direction
         ENDDO
      ENDIF
       
      !!! perform LU-factorization of matrix AG according to banded storage technique
      DO IC = 2, SB%NC
         SP%LDX (IC) = SP%LDX(IC) / SP%MDX(IC-1)
         SP%MDX (IC) = SP%MDX(IC) - SP%LDX(IC) * SP%UDX(IC-1)
      ENDDO
       
      !!! replace diagonal values diag(i) by 1/diag(i) and multiply UDX with 1/diag(i)
      DO IC = 1, SB%NC
         SP%MDX (IC) = 1.0_EB / SP%MDX(IC)
         SP%UDX (IC) = SP%MDX(IC) * SP%UDX(IC)
      ENDDO
   
END SELECT

END SUBROUTINE SCARC_SETUP_GSTRIX
 
 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! GSTRIX preconditioner/smoother
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_GSTRIX (NVECTOR, NL)
INTEGER, INTENT(IN) :: NVECTOR, NL
REAL(EB), POINTER, DIMENSION(:,:,:) :: VB
REAL(EB), POINTER, DIMENSION(:)     :: VC
INTEGER , POINTER :: NX, NY, NZ
INTEGER :: NM, I, J, K, IC, JC
TYPE (SCARC_PRECON_TYPE) , POINTER :: SP
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC


SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)
   
   !!!-------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         VB => POINT_TO_BVECTOR (NVECTOR, NM, NL)

         SB => SCARC(NM)%BANDED(NL)
         SP => SCARC(NM)%PRECON(NL)
         
         NX => SB%NX
         NY => SB%NY
         NZ => SB%NZ
         WRITE(*,*) 'ACHTUNG, NOCH ANPASSEN!'
         
         SELECT_BANDED_DIMENSION: SELECT CASE (TYPE_DIMENSION)
         
            !!!--------------- 2D -----------------
            CASE (NSCARC_DIMENSION_TWO)
         
               ! backward elimination of first NX unkowns (may be solved by tridiagonal system)
               DO I=2,NX
                  VB(I,1,1) = VB(I,1,1)-SP%LDX(I-1)*VB(I-1,1,1)
               ENDDO
               DO I=1,NX
                  VB(I,1,1) = VB(I,1,1)*SP%MDX(I)
               ENDDO
               DO I=NX-1,1,-1
                  VB(I,1,1) = VB(I,1,1)-SP%UDX(I)*VB(I+1,1,1)
               ENDDO
                 
               
               ! backward elimination of following unknowns (here the subdiagonal in z-direction must be taken into account)
               DO K=2,NZ
               
                  IC = (K-1)*NX + I
               
                  ! eliminate subdiagonal in z-direction into right hand side (related solution component already known)
                  DO I=1,NX
                     VB(I,1,K) = VB(I,1,K) - SP%MDZ(IC)*VB(I,1,K-1) 
                  ENDDO
               
                  ! perform elimination of matrix lines corresponding to K
                  DO I=2,NX
                     VB(I,1,K) = VB(I,1,K)-SP%LDX(IC-1)*VB(I-1,1,K)
                  ENDDO
                  DO I=1,NX
                     VB(I,1,K) = VB(I,1,K)*SP%MDX(IC)
                  ENDDO
                  DO I=NX-1,1,-1
                     VB(I,1,K) = VB(I,1,K)-SP%UDX(IC)*VB(I+1,1,K)
                  ENDDO
                 
               ENDDO
               
            !!!--------------- 3D -----------------
            CASE (NSCARC_DIMENSION_THREE)
            
               !!! NOT WORKING YET, has still to be adopted to 3D !!!!!
               DO J=1,NY
               
                  ! backward elimination of first NX unkowns (may be solved by tridiagonal system)
                  DO I=2,NX
                     VB(I,J,1) = VB(I,J,1)-SP%LDX(I-1)*VB(I-1,J,1)
                  ENDDO
                  DO I=1,NX
                     VB(I,J,1) = VB(I,J,1)*SP%MDX(I)
                  ENDDO
                  DO I=NX-1,1,-1
                     VB(I,J,1) = VB(I,J,1)-SP%UDX(I)*VB(I+1,J,1)
                  ENDDO
                    
                  ! backward elimination of following unknowns 
                  ! (here the subdiagonals in y- and z-direction must be taken into account)
                  DO K=2,NZ
                  
                     IC = (K-1)*NX + I
                  
                     ! bring subdiagonal in z-direction to right hand side (corresponding solution component already known)
                     DO I=1,NX
                        VB(I,J,K) = VB(I,J,K) - SP%MDZ(IC)*VB(I,J,K-1) 
                     ENDDO
                  
                     ! perform elimination of matrix lines corresponding to K
                     DO I=2,NX
                        VB(I,J,K) = VB(I,J,K)-SP%LDX(IC-1)*VB(I-1,J,K)
                     ENDDO
                     DO I=1,NX
                        VB(I,J,K) = VB(I,J,K)*SP%MDX(IC)
                     ENDDO
                     DO I=NX-1,1,-1
                        VB(I,J,K) = VB(I,J,K)-SP%UDX(IC)*VB(I+1,J,K)
                     ENDDO
                    
                  ENDDO
               
               ENDDO
               
         END SELECT SELECT_BANDED_DIMENSION

      ENDDO
       

   !!!-------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!-------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX

         VC => POINT_TO_CVECTOR (NVECTOR, NM, NL)

         SC => SCARC(NM)%COMPACT(NL)
         SP => SCARC(NM)%PRECON(NL)
         
         NX => SC%NX
         NY => SC%NY
         NZ => SC%NZ
         
         SELECT_COMPACT_DIMENSION: SELECT CASE (TYPE_DIMENSION)
         
            !!!--------------- 2D -----------------
            CASE (NSCARC_DIMENSION_TWO)
         
               ! backward elimination of first NX unkowns (may be solved by tridiagonal system)
               DO IC=2,NX
                  VC(IC) = VC(IC)-SP%LDX(I-1)*VC(IC-1)
               ENDDO
               DO I=1,NX
                  VC(IC) = VC(IC)*SP%MDX(I)
               ENDDO
               DO I=NX-1,1,-1
                  VC(IC) = VC(IC)-SP%UDX(I)*VC(IC+1)
               ENDDO
                 
               
               ! backward elimination of following unknowns (here the subdiagonal in z-direction must be taken into account)
               DO K=2,NZ
               
                  IC = (K-1)*NX + I
               
                  ! eliminate subdiagonal in z-direction into right hand side (related solution component already known)
                  DO I=1,NX
                     VC(IC) = VC(IC) - SP%MDZ(IC)*VC(IC-1) 
                  ENDDO
               
                  ! perform elimination of matrix lines corresponding to K
                  DO I=2,NX
                     VC(IC) = VC(IC)-SP%LDX(IC-1)*VC(IC-1)
                  ENDDO
                  DO I=1,NX
                     VC(IC) = VC(IC)*SP%MDX(IC)
                  ENDDO
                  DO I=NX-1,1,-1
                     VC(IC) = VC(IC)-SP%UDX(IC)*VC(IC+1)
                  ENDDO
                 
               ENDDO
               
            !!!--------------- 3D -----------------
            CASE (NSCARC_DIMENSION_THREE)
            
               !!! NOT WORKING YET, has still to be adopted to 3D !!!!!
               DO J=1,NY
               
                  JC = J*NX
            
                  ! backward elimination of first NX unkowns (may be solved by tridiagonal system)
                  DO I=2,NX
                     VC(JC+I) = VC(JC+I)-SP%LDX(I-1)*VC(JC+I-1)
                  ENDDO
                  DO I=1,NX
                     VC(JC+I) = VC(JC+I)*SP%MDX(I)
                  ENDDO
                  DO I=NX-1,1,-1
                     VC(JC+I) = VC(JC+I)-SP%UDX(I)*VC(JC+I+1)
                  ENDDO
                    
                  ! backward elimination of following unknowns 
                  ! (here the subdiagonals in y- and z-direction must be taken into account)
                  DO K=2,NZ
                  
                     IC = (K-1)*NX*NY + (J-1)*NX + I
                  
                     ! bring subdiagonal in z-direction to right hand side (corresponding solution component already known)
                     DO I=1,NX
                        VC(IC) = VC(IC) - SP%MDZ(IC)*VC(IC-1) 
                     ENDDO
                  
                     ! perform elimination of matrix lines corresponding to K
                     DO I=2,NX
                        VC(IC) = VC(IC)-SP%LDX(IC-1)*VC(IC-1)
                     ENDDO
                     DO I=1,NX
                        VC(IC) = VC(IC)*SP%MDX(IC)
                     ENDDO
                     DO I=NX-1,1,-1
                        VC(IC) = VC(IC)-SP%UDX(IC)*VC(IC+1)
                     ENDDO
                    
                  ENDDO
               
               ENDDO
            
         END SELECT SELECT_COMPACT_DIMENSION
          
      ENDDO

END SELECT SELECT_SYSTEM

END SUBROUTINE SCARC_GSTRIX


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Setup environement in every solver call (i.e. set pointers to used vectors)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_SCOPE(SCOPE, NSCOPE, NPRECON, NRHS, NL)
INTEGER, INTENT(IN)  :: NSCOPE, NPRECON, NRHS
INTEGER, INTENT(OUT) :: NL
TYPE (SCARC_SCOPE_TYPE), INTENT(OUT):: SCOPE

TYPE_SCOPE  = NSCOPE

SELECT CASE (NSCOPE)
   CASE (NSCARC_SCOPE_COARSE)
      TYPE_METHOD = NSCARC_METHOD_KRYLOV
   CASE (NSCARC_SCOPE_PRECON)
      TYPE_METHOD = NSCARC_METHOD_MULTIGRID
   CASE DEFAULT
      TYPE_METHOD = TYPE_METHOD
END SELECT

SCOPE%RESIN = 1.0_EB
SCOPE%RES   = 0.0_EB

SELECT CASE (TYPE_METHOD)
   
   !!!-------------------------------------------------------------------------------------------------------
   !!! Krylov method
   !!!-------------------------------------------------------------------------------------------------------
   CASE (NSCARC_METHOD_KRYLOV)

      TYPE_PRECON = NPRECON

      SELECT CASE (TYPE_KRYLOV)
      
         !!! CG-method
         CASE (NSCARC_KRYLOV_CG)
      
            SCOPE%F = NRHS                                             ! set correct right hand side vector

            SELECT CASE (NSCOPE)
               CASE (NSCARC_SCOPE_MAIN)

                  NL = NLEVEL_MIN

                  SCOPE%CROUTINE = 'SCARC_GLOBAL_CG'
                  SCOPE%OMEGA    =  SCARC_PRECON_OMEGA
                  SCOPE%EPS      =  SCARC_KRYLOV_ACCURACY
                  SCOPE%NIT      =  SCARC_KRYLOV_ITERATIONS

                  SCOPE%X = NSCARC_VECTOR_X
                  SCOPE%D = NSCARC_VECTOR_D
                  SCOPE%G = NSCARC_VECTOR_G
                  SCOPE%Y = NSCARC_VECTOR_Y
                  SCOPE%W = NSCARC_VECTOR_W

                  !TYPE_ACCURACY = NSCARC_ACCURACY_RELATIVE
               CASE (NSCARC_SCOPE_COARSE)

                  NL = NLEVEL_MAX

                  SCOPE%CROUTINE = 'SCARC_COARSE_CG'
                  SCOPE%OMEGA    =  SCARC_COARSE_OMEGA
                  SCOPE%EPS      =  SCARC_COARSE_ACCURACY
                  SCOPE%NIT      =  SCARC_COARSE_ITERATIONS

                  IF (TYPE_METHOD0 == NSCARC_METHOD_MULTIGRID) THEN              !  pure MG-method
                     SCOPE%X = NSCARC_VECTOR_X                                   !  take first-stage MG-vectors
                     SCOPE%D = NSCARC_VECTOR_D 
                     SCOPE%G = NSCARC_VECTOR_G 
                     SCOPE%Y = NSCARC_VECTOR_Y 
                     SCOPE%W = NSCARC_VECTOR_W 
                  ELSE                                                           ! CG-MG-method
                     SCOPE%X = NSCARC_VECTOR_X2                                  ! take second-stage MG-vectors
                     SCOPE%D = NSCARC_VECTOR_D2
                     SCOPE%G = NSCARC_VECTOR_G2
                     SCOPE%Y = NSCARC_VECTOR_Y2
                     SCOPE%W = NSCARC_VECTOR_W2
                  ENDIF

                  !TYPE_ACCURACY = NSCARC_ACCURACY_ABSOLUTE
            END SELECT
      
         !!! BICG-method
         CASE (NSCARC_KRYLOV_BICG)
      
            SCOPE%F = NRHS                                             ! set correct right hand side vector

            SELECT CASE (NSCOPE)
               CASE (NSCARC_SCOPE_MAIN)

                  NL = NLEVEL_MIN

                  SCOPE%CROUTINE = 'SCARC_GLOBAL_BICG'
                  SCOPE%OMEGA    =  SCARC_PRECON_OMEGA
                  SCOPE%EPS      =  SCARC_KRYLOV_ACCURACY
                  SCOPE%NIT      =  SCARC_KRYLOV_ITERATIONS

                  SCOPE%X = NSCARC_VECTOR_X
                  SCOPE%D = NSCARC_VECTOR_D
                  SCOPE%G = NSCARC_VECTOR_G
                  SCOPE%Y = NSCARC_VECTOR_Y
                  SCOPE%W = NSCARC_VECTOR_W
                  SCOPE%Z = NSCARC_VECTOR_Z
                  !TYPE_ACCURACY = NSCARC_ACCURACY_RELATIVE

               CASE (NSCARC_SCOPE_COARSE)

                  NL = NLEVEL_MAX

                  SCOPE%CROUTINE = 'SCARC_COARSE_BICG'
                  SCOPE%OMEGA    =  SCARC_COARSE_OMEGA
                  SCOPE%EPS      =  SCARC_COARSE_ACCURACY
                  SCOPE%NIT      =  SCARC_COARSE_ITERATIONS

                  IF (TYPE_METHOD0 == NSCARC_METHOD_MULTIGRID) THEN              !  pure MG-method
                     SCOPE%X = NSCARC_VECTOR_X                                   !  take first-stage MG-vectors
                     SCOPE%D = NSCARC_VECTOR_D 
                     SCOPE%G = NSCARC_VECTOR_G 
                     SCOPE%Y = NSCARC_VECTOR_Y 
                     SCOPE%W = NSCARC_VECTOR_W 
                     SCOPE%Z = NSCARC_VECTOR_Z 
                  ELSE                                                           ! CG-MG-method
                     SCOPE%X = NSCARC_VECTOR_X2                                  ! take second-stage MG-vectors
                     SCOPE%D = NSCARC_VECTOR_D2
                     SCOPE%G = NSCARC_VECTOR_G2
                     SCOPE%Y = NSCARC_VECTOR_Y2
                     SCOPE%W = NSCARC_VECTOR_W2
                     SCOPE%Z = NSCARC_VECTOR_Z2
                  ENDIF

                  !TYPE_ACCURACY = NSCARC_ACCURACY_ABSOLUTE

            END SELECT
      
      END SELECT
   
   !!!-------------------------------------------------------------------------------------------------------
   !!! Multigrid method
   !!!-------------------------------------------------------------------------------------------------------
   CASE (NSCARC_METHOD_MULTIGRID)

      TYPE_SMOOTH = NPRECON
      TYPE_PRECON = NPRECON

      SCOPE%EPS   = SCARC_MULTIGRID_ACCURACY
      SCOPE%NIT   = SCARC_MULTIGRID_ITERATIONS
      SCOPE%OMEGA = SCARC_SMOOTH_OMEGA

      NL = NLEVEL_MIN
      SCOPE%F = NRHS                                                   ! set correct right hand side vector

      !!! select scope (multigrid as main solver or preconditioner)
      SELECT CASE (NSCOPE)
         CASE (NSCARC_SCOPE_MAIN)

            SCOPE%CROUTINE = 'SCARC_GLOBAL_MULTIGRID'

            SCOPE%X = NSCARC_VECTOR_X
            SCOPE%D = NSCARC_VECTOR_D

            !TYPE_ACCURACY = NSCARC_ACCURACY_RELATIVE

         CASE (NSCARC_SCOPE_PRECON)

            SCOPE%CROUTINE = 'SCARC_PRECON_MULTIGRID'

            SCOPE%X = NSCARC_VECTOR_X2
            SCOPE%D = NSCARC_VECTOR_D2

            !TYPE_ACCURACY = NSCARC_ACCURACY_RELATIVE

      END SELECT

END SELECT
   
END SUBROUTINE SCARC_SETUP_SCOPE


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set initial solution corresponding to boundary data in BXS, BXF, ...
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SETUP_SOLVER(NL)
INTEGER, INTENT(IN) :: NL
INTEGER :: NM, IW, IOR0, I, J, K, IC
!REAL(EB):: LINE(10)
TYPE (MESH_TYPE), POINTER ::  M
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC


SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

   !!!-------------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!-------------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      SELECT_BANDED_METHOD: SELECT CASE (TYPE_METHOD)

         !!! In case of a Krylov method initialize auxiliary arrays
         CASE (NSCARC_METHOD_KRYLOV)

            DO NM = NMESHES_MIN, NMESHES_MAX
               SCARC(NM)%BANDED(NL)%D = 0.0_EB
               SCARC(NM)%BANDED(NL)%G = 0.0_EB
               SCARC(NM)%BANDED(NL)%Y = 0.0_EB
               SCARC(NM)%BANDED(NL)%W = 0.0_EB
            ENDDO

            IF (TYPE_KRYLOV == NSCARC_KRYLOV_BICG) THEN
               DO NM = NMESHES_MIN, NMESHES_MAX
                  SCARC(NM)%BANDED(NL)%Z = 0.0_EB
               ENDDO
            ENDIF
            
            IF (TYPE_PRECON == NSCARC_PRECON_MULTIGRID) THEN
               
            ENDIF

         !!! In case of a multigrid method with coarse grid solution by CG, clear CG-vectors on max level
         CASE (NSCARC_METHOD_MULTIGRID)
            
            IF (TYPE_COARSE == NSCARC_COARSE_ITERATIVE) THEN
               DO NM = NMESHES_MIN, NMESHES_MAX
                  SCARC(NM)%BANDED(NLEVEL_MAX)%X = 0.0_EB
                  SCARC(NM)%BANDED(NLEVEL_MAX)%D = 0.0_EB
                  SCARC(NM)%BANDED(NLEVEL_MAX)%G = 0.0_EB
                  SCARC(NM)%BANDED(NLEVEL_MAX)%Y = 0.0_EB
                  SCARC(NM)%BANDED(NLEVEL_MAX)%W = 0.0_EB
               ENDDO
            ENDIF

      END SELECT SELECT_BANDED_METHOD

      IF (TYPE_SCOPE == NSCARC_SCOPE_MAIN) THEN
               
         !!! Initialize solution and right hand side vector corresponding to boundary conditions
         SELECT_BANDED_DIMENSION: SELECT CASE (TYPE_DIMENSION)
         
            !!! -------------- 2D ------------------
            CASE (NSCARC_DIMENSION_TWO)

               DO NM = NMESHES_MIN, NMESHES_MAX
         
                  M  => MESHES(NM)
                  SB => SCARC(NM)%BANDED(NL)
               
                  ! get right hand side vector
                  SB%F (1:M%IBAR, 1, 1:M%KBAR) = M%PRHS (1:M%IBAR, 1, 1:M%KBAR)
            
                  ! set ghost values of solution vector to zero and use values of H/HS in interior
                  SB%X(1:M%IBAR, 1, 0       ) = 0.0_EB
                  SB%X(1:M%IBAR, 1, M%KBAR+1) = 0.0_EB
                  SB%X(0       , 1, 1:M%KBAR) = 0.0_EB
                  SB%X(M%IBAR+1, 1, 1:M%KBAR) = 0.0_EB
                  IF (PREDICTOR) THEN
                     SB%X (1:M%IBAR, 1, 1:M%KBAR) = M%H (1:M%IBAR, 1, 1:M%KBAR)
                  ELSE
                     SB%X (1:M%IBAR, 1, 1:M%KBAR) = M%HS(1:M%IBAR, 1, 1:M%KBAR)
                  ENDIF
            
                  ! set boundary conditions at exterior boundaries (corresponding to pois.f90)
                  BANDED_WALLCELL_LOOP2D: DO IW = 1, M%N_EXTERNAL_WALL_CELLS
               
                     I    = SB%WALL(IW)%IXW   
                     J    = SB%WALL(IW)%IYW
                     K    = SB%WALL(IW)%IZW 
                     IOR0 = SB%WALL(IW)%IOR
            
                     IF (J /= 1) THEN
                        WRITE(*,*) 'Wrong index for J =',J,' in SCARC_SETUP_SOLVER !!!'
                        STOP
                     ENDIF
                  
                  
                     SELECT CASE (IOR0)
                        CASE (1)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DXI2 * M%BXS(1,K)         ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) + SB%DXI * M%BXS(1,K)                   ! Neumann
                           ENDIF
                        CASE (-1)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DXI2 *M%BXF(1,K)          ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - SB%DXI *M%BXF(1,K)                    ! Neumann
                           ENDIF
                        CASE (3)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DZI2 * M%BZS(I,1)         ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) + SB%DZI * M%BZS(I,1)                   ! Neumann
                           ENDIF
                        CASE (-3)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DZI2 * M%BZF(I,1)         ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - SB%DZI  * M%BZF(I,1)                  ! Neumann
                           ENDIF
                     END SELECT
                  
                  ENDDO BANDED_WALLCELL_LOOP2D
               
               ENDDO
            
            !!! -------------- 3D ------------------
            CASE (NSCARC_DIMENSION_THREE)
            
               DO NM = NMESHES_MIN, NMESHES_MAX
               
                  M  => MESHES(NM)
                  SB => SCARC(NM)%BANDED(NL)
            
                  ! get right hand side vector
                  SB%F (1:M%IBAR, 1:M%JBAR, 1:M%KBAR) = M%PRHS (1:M%IBAR, 1:M%JBAR, 1:M%KBAR)
            
                  ! set ghost values of solution vector to zero and use values of H/HS in interior
                  SB%X(1:M%IBAR, 1:M%JBAR, 0       ) = 0.0_EB
                  SB%X(1:M%IBAR, 1:M%JBAR, M%KBAR+1) = 0.0_EB
                  SB%X(1:M%IBAR, 0       , 1:M%KBAR) = 0.0_EB
                  SB%X(1:M%IBAR, M%JBAR+1, 1:M%KBAR) = 0.0_EB
                  SB%X(0       , 1:M%JBAR, 1:M%KBAR) = 0.0_EB
                  SB%X(M%IBAR+1, 1:M%JBAR, 1:M%KBAR) = 0.0_EB
                  IF (PREDICTOR) THEN
                     SB%X (1:M%IBAR, 1:M%JBAR, 1:M%KBAR) = M%H (1:M%IBAR, 1:M%JBAR, 1:M%KBAR)
                  ELSE
                     SB%X (1:M%IBAR, 1:M%JBAR, 1:M%KBAR) = M%HS(1:M%IBAR, 1:M%JBAR, 1:M%KBAR)
                  ENDIF
            
                  BANDED_WALLCELL_LOOP3D: DO IW = 1, M%N_EXTERNAL_WALL_CELLS
                  
                     I    = SB%WALL(IW)%IXW 
                     J    = SB%WALL(IW)%IYW
                     K    = SB%WALL(IW)%IZW 
                     IOR0 = SB%WALL(IW)%IOR
                  
                     SELECT CASE (IOR0)
                        CASE (1)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DXI2 * M%BXS(J,K)         ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) + SB%DXI * M%BXS(J,K)                   ! Neumann
                           ENDIF
                        CASE (-1)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DXI2 *M%BXF(J,K)          ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - SB%DXI *M%BXF(J,K)                    ! Neumann
                           ENDIF
                        CASE (2)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DYI2 * M%BYS(I,K)         ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) + SB%DYI * M%BYS(I,K)                   ! Neumann
                           ENDIF
                        CASE (-2)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DYI2 *M%BYF(I,K)          ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - SB%DYI *M%BYF(I,K)                    ! Neumann
                           ENDIF
                        CASE (3)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DZI2 * M%BZS(I,J)         ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) + SB%DZI * M%BZS(I,J)                   ! Neumann
                           ENDIF
                        CASE (-3)
                           IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - 2.0_EB * SB%DZI2 * M%BZF(I,J)         ! Dirichlet
                           ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                              SB%F(I,J,K) = SB%F(I,J,K) - SB%DZI  * M%BZF(I,J)                  ! Neumann
                           ENDIF
                     END SELECT
                  
                  ENDDO BANDED_WALLCELL_LOOP3D
            
               ENDDO
         
         END SELECT SELECT_BANDED_DIMENSION

   

      ENDIF
         
   !!!-------------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!-------------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      SELECT_COMPACT_METHOD: SELECT CASE (TYPE_METHOD)

         !!! In case of a Krylov method initialize auxiliary arrays
         CASE (NSCARC_METHOD_KRYLOV)

            DO NM = NMESHES_MIN, NMESHES_MAX
               SC => SCARC(NM)%COMPACT(NL)
               DO IC = SC%NC+1, SC%NCE
                  SC%D(IC) = 0.0_EB
                  SC%G(IC) = 0.0_EB
                  SC%Y(IC) = 0.0_EB
                  SC%W(IC) = 0.0_EB
               ENDDO
            ENDDO

            IF (TYPE_KRYLOV == NSCARC_KRYLOV_BICG) THEN
               DO NM = NMESHES_MIN, NMESHES_MAX
                  SC => SCARC(NM)%COMPACT(NL)
                  DO IC = SC%NC+1, SC%NCE
                     SC%Z(IC) = 0.0_EB
                  ENDDO
               ENDDO
            ENDIF
            
         !!! In case of a multigrid method with coarse grid solution by CG, clear CG-vectors on max level
         CASE (NSCARC_METHOD_MULTIGRID)
            
            DO NM = NMESHES_MIN, NMESHES_MAX
               SC => SCARC(NM)%COMPACT(NL)
               DO IC = SC%NC+1, SC%NCE
                  SC%D = 0.0_EB
               ENDDO
               SC => SCARC(NM)%COMPACT(NLEVEL_MAX)
               DO IC = SC%NC+1, SC%NCE
                  SC%G = 0.0_EB
                  SC%W = 0.0_EB
               ENDDO
               
            ENDDO

      END SELECT SELECT_COMPACT_METHOD
      
      IF (TYPE_SCOPE == NSCARC_SCOPE_MAIN) THEN
         
         !!! Initialize solution and right hand side vector corresponding to boundary conditions
         SELECT_COMPACT_DIMENSION: SELECT CASE (TYPE_DIMENSION)
         
            !!! -------------- 2D ------------------
            CASE (NSCARC_DIMENSION_TWO)
         
               DO NM = NMESHES_MIN, NMESHES_MAX
         
                  M  => MESHES(NM)
                  SC => SCARC(NM)%COMPACT(NL)
               
                  ! get right hand side and initial vector
                  DO K = 1, M%KBAR
                     DO I = 1, M%IBAR
                        IC = (K-1)*M%IBAR + I
                        SC%F(IC) = M%PRHS (I, 1, K)
                        IF (PREDICTOR) THEN
                           SC%X(IC) = M%H (I, 1, K)
                        ELSE
                           SC%X(IC) = M%HS(I, 1, K)
                        ENDIF
                     ENDDO
                  ENDDO
            
            
                  ! set boundary conditions at exterior boundaries (corresponding to pois.f90)
                  COMPACT_WALLCELL_LOOP2D: DO IW = 1, M%N_EXTERNAL_WALL_CELLS
               
                     I    = SC%WALL(IW)%IXW 
                     J    = SC%WALL(IW)%IYW 
                     K    = SC%WALL(IW)%IZW 
                     IC   = SC%WALL(IW)%ICW 
                     IOR0 = SC%WALL(IW)%IOR
            
                     IF (J /= 1) THEN
                        WRITE(*,*) 'Wrong index for J =',J,' in SCARC_SETUP_SOLVER !!!'
                        STOP
                     ENDIF

                     SELECT CASE (IOR0)
                        CASE (1)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DXI2 * M%BXS(1,K)         ! Dirichlet
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) + SC%DXI * M%BXS(1,K)                   ! Neumann
                           ENDIF
                        CASE (-1)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DXI2 *M%BXF(1,K)          ! Dirichlet
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) - SC%DXI *M%BXF(1,K)                    ! Neumann
                           ENDIF
                        CASE (3)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DZI2 * M%BZS(I,1)         ! Dirichlet
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) + SC%DZI * M%BZS(I,1)                   ! Neumann
                           ENDIF
                        CASE (-3)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DZI2 * M%BZF(I,1)         ! Dirichlet
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) - SC%DZI  * M%BZF(I,1)                  ! Neumann
                           ENDIF
                     END SELECT
                  
                  ENDDO COMPACT_WALLCELL_LOOP2D
         
               ENDDO
            !!! -------------- 3D ------------------
            CASE (NSCARC_DIMENSION_THREE)
            
               DO NM = NMESHES_MIN, NMESHES_MAX
         
                  M  => MESHES(NM)
                  SC => SCARC(NM)%COMPACT(NL)
            
                  ! get right hand side and initial vector
                  DO K = 1, M%KBAR
                     DO J = 1, M%JBAR
                        DO I = 1, M%IBAR
                           IC = (K-1) * M%IBAR * M%JBAR + (J-1) * M%IBAR + I
                           SC%F(IC) = M%PRHS (I, J, K)
                           IF (PREDICTOR) THEN
                              SC%X(IC) = M%H (I, J, K)
                           ELSE
                              SC%X(IC) = M%HS(I, J, K)
                           ENDIF
                        ENDDO
                     ENDDO
                  ENDDO
            
                  COMPACT_WALLCELL_LOOP3D: DO IW = 1, M%N_EXTERNAL_WALL_CELLS
                  
                     I    = SC%WALL(IW)%IXW 
                     J    = SC%WALL(IW)%IYW 
                     K    = SC%WALL(IW)%IZW 
                     IC   = SC%WALL(IW)%ICW 
                     IOR0 = SC%WALL(IW)%IOR
                  
                     SELECT CASE (IOR0)
                        CASE (1)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DXI2 * M%BXS(J,K)         ! Dirichlet
!WRITE(*,*) 'A:F(',I,',',J,',',K,')=',SC%F(IC)
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) + SC%DXI * M%BXS(J,K)                   ! Neumann
!WRITE(*,*) 'B:F(',I,',',J,',',K,')=',SC%F(IC)
                           ENDIF
                        CASE (-1)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DXI2 *M%BXF(J,K)          ! Dirichlet
!WRITE(*,*) 'C:F(',I,',',J,',',K,')=',SC%F(IC)
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) - SC%DXI *M%BXF(J,K)                    ! Neumann
!WRITE(*,*) 'D:F(',I,',',J,',',K,')=',SC%F(IC)
                           ENDIF
                        CASE (2)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DYI2 * M%BYS(I,K)         ! Dirichlet
!WRITE(*,*) 'E:F(',I,',',J,',',K,')=',SC%F(IC)
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) + SC%DYI * M%BYS(I,K)                   ! Neumann
!WRITE(*,*) 'F:F(',I,',',J,',',K,')=',SC%F(IC)
                           ENDIF
                        CASE (-2)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DYI2 *M%BYF(I,K)          ! Dirichlet
!WRITE(*,*) 'G:F(',I,',',J,',',K,')=',SC%F(IC)
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) - SC%DYI *M%BYF(I,K)                    ! Neumann
!WRITE(*,*) 'H:F(',I,',',J,',',K,')=',SC%F(IC)
                           ENDIF
                        CASE (3)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DZI2 * M%BZS(I,J)         ! Dirichlet
!WRITE(*,*) 'I:F(',I,',',J,',',K,')=',SC%F(IC)
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) + SC%DZI * M%BZS(I,J)                   ! Neumann
!WRITE(*,*) 'J:F(',I,',',J,',',K,')=',SC%F(IC)
                           ENDIF
                        CASE (-3)
                           IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                              SC%F(IC) = SC%F(IC) - 2.0_EB * SC%DZI2 * M%BZF(I,J)         ! Dirichlet
!WRITE(*,*) 'K:F(',I,',',J,',',K,')=',SC%F(IC)
                           ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                              SC%F(IC) = SC%F(IC) - SC%DZI  * M%BZF(I,J)                  ! Neumann
!WRITE(*,*) 'L:F(',I,',',J,',',K,')=',SC%F(IC)
                           ENDIF
                     END SELECT
                  
!IF (J==5.AND.K==5) THEN
!   IF (I==1)  LINE(1)=SC%F(IC)
!   IF (I==2)  LINE(2)=SC%F(IC)
!   IF (I==3)  LINE(3)=SC%F(IC)
!   IF (I==4)  LINE(4)=SC%F(IC)
!   IF (I==5)  LINE(5)=SC%F(IC)
!   IF (I==16) LINE(6)=SC%F(IC)
!   IF (I==17) LINE(7)=SC%F(IC)
!   IF (I==18) LINE(8)=SC%F(IC)
!   IF (I==19) LINE(9)=SC%F(IC)
!   IF (I==20) LINE(10)=SC%F(IC)
!ENDIF
                  ENDDO COMPACT_WALLCELL_LOOP3D
         
               ENDDO
         
!WRITE(*,'(a10,10f12.6)') 'F(,5,5)', LINE(1:10)

         END SELECT SELECT_COMPACT_DIMENSION

      ELSE IF (TYPE_SCOPE == NSCARC_SCOPE_COARSE) THEN
         DO NM = NMESHES_MIN, NMESHES_MAX
            SCARC(NM)%COMPACT(NLEVEL_MAX)%X = 0.0_EB
         ENDDO
      ENDIF

END SELECT SELECT_SYSTEM

END SUBROUTINE SCARC_SETUP_SOLVER

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Print out residual information for loop ITE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_CONVERGENCE_INFO(RES, ITE, NL, CROUTINE)
INTEGER, INTENT(IN) :: ITE, NL
REAL(EB), INTENT(IN) :: RES
CHARACTER(*), INTENT(IN) :: CROUTINE
INTEGER:: NM

DO NM = NMESHES_MIN, NMESHES_MAX
   IF (TYPE_DEBUG >= NSCARC_DEBUG_LESS) WRITE(SCARC_LU,1000) TRIM(CROUTINE), NM, NL, ITE,  RES
   IF (TYPE_DEBUG >= NSCARC_DEBUG_LESS.AND.MYID==0) write(*,1000) TRIM(CROUTINE), NM, NL, ITE,  RES
ENDDO

1000 FORMAT (5X,A30,': mesh', i4,': level=',i4,': #ite= ',i4,': res =',e25.16)
END SUBROUTINE SCARC_CONVERGENCE_INFO


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Check if solver converges or diverges and print out residual information
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
INTEGER FUNCTION SCARC_CONVERGENCE_STATE(SCOPE, ITE, NL)
INTEGER, INTENT(IN) :: ITE, NL
INTEGER :: ISTATE
TYPE (SCARC_SCOPE_TYPE), INTENT(IN) :: SCOPE

ISTATE = NSCARC_STATE_PROCEED
SCARC_RESIDUAL = SCOPE%RES

IF (TYPE_DEBUG >= NSCARC_DEBUG_INFO2) WRITE(SCARC_LU,1000) TRIM(SCOPE%CROUTINE), NL, ITE, SCOPE%RES
IF (TYPE_DEBUG >= NSCARC_DEBUG_INFO2.AND.MYID==0) WRITE(*,1000) TRIM(SCOPE%CROUTINE), NL, ITE, SCOPE%RES

SELECT CASE (TYPE_ACCURACY)
   CASE (NSCARC_ACCURACY_RELATIVE)
      IF (SCOPE%RES <= SCOPE%RESIN*SCOPE%EPS)  ISTATE = NSCARC_STATE_CONV
      IF (SCOPE%RES <= 1.0E-15)                ISTATE = NSCARC_STATE_CONV
   CASE (NSCARC_ACCURACY_ABSOLUTE)
      IF (SCOPE%RES <= SCOPE%EPS .AND. SCOPE%RES <= SCOPE%RESIN*SCARC_ACCURACY_RELATIVE) ISTATE = NSCARC_STATE_CONV
END SELECT
IF (SCOPE%RES > SCARC_ACCURACY_DIVERGENCE) ISTATE = NSCARC_STATE_DIVG

SCARC_CONVERGENCE_STATE = ISTATE
RETURN

1000 FORMAT (5X,A30,': level=',i4,': #ite= ',i4,': res =',e25.16)
END FUNCTION SCARC_CONVERGENCE_STATE


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Compute convergence rate and print out resiual information for final loop
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_CONVERGENCE_RATE(SCOPE, ITE, ISTATE)
INTEGER, INTENT(IN) :: ITE, ISTATE
INTEGER  :: ITERATIONS
REAL(EB) :: RESIDUAL, CAPPA
TYPE (SCARC_SCOPE_TYPE), INTENT(IN) :: SCOPE

RESIDUAL = SCOPE%RES
IF (ISTATE == NSCARC_STATE_DIVG) THEN                       
   ITERATIONS = - 1
   CAPPA      = 1.0_EB
ELSE 
   IF (ISTATE == NSCARC_STATE_CONV) THEN
     ITERATIONS = ITE
   ELSE
     ITERATIONS = ITE-1
   ENDIF
   IF (SCOPE%RESIN >= 1.0E-70_EB) THEN
      CAPPA = (SCOPE%RES/SCOPE%RESIN) ** (1.0_EB/ITERATIONS)
   ELSE 
      CAPPA = 0.0_EB
   ENDIF
ENDIF

IF (TYPE_SCOPE == NSCARC_SCOPE_MAIN) THEN
   SCARC_CAPPA      = CAPPA
   SCARC_RESIDUAL   = RESIDUAL
   SCARC_ITERATIONS = ITERATIONS
ENDIF

IF (TYPE_DEBUG >= NSCARC_DEBUG_MUCH.AND.TYPE_METHOD==TYPE_METHOD0.AND.TYPE_SCOPE==NSCARC_SCOPE_MAIN) THEN
   WRITE(SCARC_LU,2000) SCOPE%CROUTINE, ITERATIONS, CAPPA 
   IF (MYID==0) WRITE(*,2000) SCOPE%CROUTINE, ITERATIONS, CAPPA 
ELSE IF (TYPE_DEBUG >= NSCARC_DEBUG_MUCH) THEN
   WRITE(SCARC_LU,2000) SCOPE%CROUTINE, ITERATIONS, CAPPA 
   IF (MYID==0) WRITE(*,2000) SCOPE%CROUTINE, ITERATIONS, CAPPA 
ENDIF
IF (TYPE_DEBUG >= NSCARC_DEBUG_MUCH) THEN
   WRITE(SCARC_LU,3000)
   IF (MYID==0) WRITE(*,3000)
ENDIF
IF (TYPE_DEBUG == NSCARC_DEBUG_MUCH.AND.TYPE_SCOPE == NSCARC_SCOPE_MAIN) THEN
   WRITE(SCARC_LU,3000)
   IF (MYID==0) WRITE(*,3000)
ENDIF

2000 FORMAT (5X,A30,': iterations: ',i6,':  convergence rate =',e14.6)
3000 FORMAT ('==========================================================================')
END SUBROUTINE SCARC_CONVERGENCE_RATE

 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform restriction from finer to coarser grid in multigrid method
!!!    - 'FI' corresponds to finer   grid
!!!    - 'CO' corresponds to coarser grid
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_RESTRICTION (NVECTOR_FI, NVECTOR_CO, NL_FI, NL_CO)
INTEGER, INTENT(IN) :: NVECTOR_FI, NVECTOR_CO, NL_FI, NL_CO
INTEGER :: NM, ICOL, IC
REAL(EB), POINTER, DIMENSION(:,:,:) :: FB_CO, DB_FI
REAL(EB), POINTER, DIMENSION(:)     :: FC_CO, DC_FI, R
INTEGER , POINTER, DIMENSION(:)     :: R_ROW, R_COL
INTEGER , POINTER :: NX_CO, NY_CO, NZ_CO, NC_CO
INTEGER  :: NX_FI, NY_FI, NZ_FI
INTEGER  :: IX_FI, IY_FI, IZ_FI, IC_FI(8)
INTEGER  :: IX_CO, IY_CO, IZ_CO, IC_CO
REAL(EB) :: AUX, AUX0

TYPE_VECTOR = NVECTOR_FI
IF (TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) CALL SCARC_EXCHANGE(NSCARC_EXCHANGE_VECTOR, NL_FI)

SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

   !!!----------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      SELECT_BANDED_MULTIGRID: SELECT CASE (TYPE_MULTIGRID)

         !!!------------------------- Geometric multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_GEOMETRIC)

            DO NM = NMESHES_MIN, NMESHES_MAX
            
               NX_CO => SCARC(NM)%BANDED(NL_CO)%NX
               NY_CO => SCARC(NM)%BANDED(NL_CO)%NY
               NZ_CO => SCARC(NM)%BANDED(NL_CO)%NZ
            
               DB_FI => POINT_TO_BVECTOR(NVECTOR_FI, NM, NL_FI)
               FB_CO => POINT_TO_BVECTOR(NVECTOR_CO, NM, NL_CO)
      
               SELECT_BANDED_DIMENSION: SELECT CASE (TYPE_DIMENSION)

                  !!!----------------- 2D -------------------
                  CASE (NSCARC_DIMENSION_TWO)
               
                     DO IZ_CO = 1, NZ_CO
                        DO IX_CO = 1, NX_CO
                 
                           IX_FI = 2*IX_CO
                           IY_FI = 1
                           IZ_FI = 2*IZ_CO
                
                           FB_CO(IX_CO, 1, IZ_CO) = 0.25_EB * (  DB_FI(IX_FI  , IY_FI, IZ_FI-1)  &
                                                               + DB_FI(IX_FI-1, IY_FI, IZ_FI-1)  &
                                                               + DB_FI(IX_FI  , IY_FI, IZ_FI  )  &
                                                               + DB_FI(IX_FI-1, IY_FI, IZ_FI  ) )
                        ENDDO
                     ENDDO
               
                  !!!----------------- 3D -------------------
                  CASE (NSCARC_DIMENSION_THREE)
                     
                     DO IZ_CO = 1, NZ_CO
                        DO IY_CO = 1, NY_CO
                           DO IX_CO = 1, NX_CO
               
                              IX_FI = 2*IX_CO
                              IY_FI = 2*IY_CO
                              IZ_FI = 2*IZ_CO
               
                              FB_CO(IX_CO, IY_CO , IZ_CO) = 0.125_EB * (  DB_FI(IX_FI-1, IY_FI-1, IZ_FI-1)  &
                                                                        + DB_FI(IX_FI  , IY_FI-1, IZ_FI-1)  &
                                                                        + DB_FI(IX_FI-1, IY_FI  , IZ_FI-1)  &
                                                                        + DB_FI(IX_FI  , IY_FI  , IZ_FI-1)  &
                                                                        + DB_FI(IX_FI-1, IY_FI-1, IZ_FI  )  &
                                                                        + DB_FI(IX_FI  , IY_FI-1, IZ_FI  )  &
                                                                        + DB_FI(IX_FI-1, IY_FI  , IZ_FI  )  &
                                                                        + DB_FI(IX_FI  , IY_FI  , IZ_FI  ) )
                           ENDDO
                        ENDDO
                     ENDDO
            
               END SELECT SELECT_BANDED_DIMENSION

            ENDDO
                  
      
         !!!------------------------- Geometric multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_ALGEBRAIC)

            WRITE(*,*) 'No banded restriction for algebraic multigrid available, stopping program!'
            STOP

      END SELECT SELECT_BANDED_MULTIGRID

      
   !!!----------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      SELECT_COMPACT_MULTIGRID: SELECT CASE (TYPE_MULTIGRID)

         !!!------------------------- Geometric multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_GEOMETRIC)

            DO NM = NMESHES_MIN, NMESHES_MAX
         
               NX_CO => SCARC(NM)%COMPACT(NL_CO)%NX
               NY_CO => SCARC(NM)%COMPACT(NL_CO)%NY
               NZ_CO => SCARC(NM)%COMPACT(NL_CO)%NZ
         
               NX_FI = 2*NX_CO
               NY_FI = 2*NY_CO
               NZ_FI = 2*NZ_CO
   
               DC_FI  => POINT_TO_CVECTOR(NVECTOR_FI, NM, NL_FI)
               FC_CO  => POINT_TO_CVECTOR(NVECTOR_CO, NM, NL_CO)

               SELECT_COMPACT_DIMENSION: SELECT CASE (TYPE_DIMENSION)
               
                  !!!----------------- 2D -------------------
                  CASE (NSCARC_DIMENSION_TWO)
               
                     DO IZ_CO = 1, NZ_CO
                        DO IX_CO = 1, NX_CO
                  
                           IX_FI = 2*IX_CO
                           IZ_FI = 2*IZ_CO
                 
                           IC_CO     = (IZ_CO-1)*NX_CO + IX_CO
                
                           IC_FI(1) = (IZ_FI-2)*NX_FI + IX_FI - 1
                           IC_FI(2) = (IZ_FI-2)*NX_FI + IX_FI   
                           IC_FI(3) = (IZ_FI-1)*NX_FI + IX_FI - 1
                           IC_FI(4) = (IZ_FI-1)*NX_FI + IX_FI    
               
                           FC_CO(IC_CO) = 0.25_EB * (  DC_FI(IC_FI(1)) &
                                                     + DC_FI(IC_FI(2)) &
                                                     + DC_FI(IC_FI(3)) &
                                                     + DC_FI(IC_FI(4)) )
               
                        ENDDO
                     ENDDO
                  
                  !!!----------------- 3D -------------------
                  CASE (NSCARC_DIMENSION_THREE)
                     
                     DO IZ_CO = 1, NZ_CO
                        DO IY_CO = 1, NY_CO
                           DO IX_CO = 1, NX_CO
                  
                              IX_FI = 2*IX_CO
                              IY_FI = 2*IY_CO
                              IZ_FI = 2*IZ_CO
                 
                              IC_CO    = (IZ_CO-1)*NX_CO*NY_CO + (IY_CO-1)*NX_CO + IX_CO
                
                              IC_FI(1) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI - 1
                              IC_FI(2) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI    
                              IC_FI(3) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI - 1
                              IC_FI(4) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI    
                              IC_FI(5) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI - 1
                              IC_FI(6) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI    
                              IC_FI(7) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI - 1
                              IC_FI(8) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI    
               
                              FC_CO(IC_CO) = 0.125_EB * (  DC_FI(IC_FI(1)) &
                                                         + DC_FI(IC_FI(2)) &
                                                         + DC_FI(IC_FI(3)) &
                                                         + DC_FI(IC_FI(4)) &
                                                         + DC_FI(IC_FI(5)) &
                                                         + DC_FI(IC_FI(6)) &
                                                         + DC_FI(IC_FI(7)) &
                                                         + DC_FI(IC_FI(8)) )
                           ENDDO
                        ENDDO
                     ENDDO
               
               END SELECT SELECT_COMPACT_DIMENSION

            ENDDO

         !!!------------------------- Algebraic multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_ALGEBRAIC)

            DO NM = NMESHES_MIN, NMESHES_MAX

               DC_FI => POINT_TO_CVECTOR(NVECTOR_FI, NM, NL_FI)
               FC_CO => POINT_TO_CVECTOR(NVECTOR_CO, NM, NL_CO)

               NC_CO => SCARC(NM)%COMPACT(NL_CO)%NC

               R     => SCARC(NM)%COMPACT(NL_FI)%R
               R_ROW => SCARC(NM)%COMPACT(NL_FI)%R_ROW
               R_COL => SCARC(NM)%COMPACT(NL_FI)%R_COL
   
               DO IC_CO = 1, NC_CO
                  AUX = 0.0_EB
                  DO ICOL = R_ROW(IC_CO), R_ROW(IC_CO+1)-1
                     IC = R_COL(ICOL)
                     AUX0 = AUX
                     AUX = AUX + DC_FI(IC) * R(ICOL)
                  ENDDO
                  FC_CO(IC_CO) = AUX
               ENDDO

            ENDDO

      END SELECT SELECT_COMPACT_MULTIGRID

END SELECT SELECT_SYSTEM

END SUBROUTINE SCARC_RESTRICTION


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Perform prolongation from coarser to finer grid in multigrid method
!!!    - 'CO' corresponds to coarser grid
!!!    - 'FI' corresponds to finer   grid
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PROLONGATION (NVECTOR_CO, NVECTOR_FI, NL_CO, NL_FI)
INTEGER, INTENT(IN) :: NVECTOR_CO, NVECTOR_FI, NL_CO, NL_FI
INTEGER :: NM, ICOL, IC, I
REAL(EB), POINTER, DIMENSION(:,:,:) :: XB_CO, DB_FI
REAL(EB), POINTER, DIMENSION(:)     :: XC_CO, DC_FI, P
INTEGER , POINTER, DIMENSION(:)     :: P_ROW, P_COL
INTEGER , POINTER, DIMENSION(:,:)   :: P_PTR
INTEGER , POINTER :: NX_CO, NY_CO, NZ_CO, NC_FI, NCE_FI
INTEGER  :: NX_FI, NY_FI, NZ_FI
INTEGER  :: IX_FI, IY_FI, IZ_FI, IC_FI(8)
INTEGER  :: IX_CO, IY_CO, IZ_CO, IC_CO
REAL(EB) :: AUX

SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

   !!!----------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      SELECT_BANDED_MULTIGRID: SELECT CASE (TYPE_MULTIGRID)

         !!!------------------------- Geometric multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_GEOMETRIC)

            DO NM = NMESHES_MIN, NMESHES_MAX
            
               NX_CO => SCARC(NM)%BANDED(NL_CO)%NX
               NY_CO => SCARC(NM)%BANDED(NL_CO)%NY
               NZ_CO => SCARC(NM)%BANDED(NL_CO)%NZ
            
               XB_CO  => POINT_TO_BVECTOR(NVECTOR_CO, NM, NL_CO)
               DB_FI  => POINT_TO_BVECTOR(NVECTOR_FI, NM, NL_FI)
      
               SELECT_BANDED_DIMENSION: SELECT CASE (TYPE_DIMENSION)

                  !!!----------------- 2D -------------------
                  CASE (NSCARC_DIMENSION_TWO)
               
                     DO IZ_CO = 1, NZ_CO
                        DO IX_CO = 1, NX_CO
               
                           IX_FI = 2*IX_CO
                           IY_FI = 1
                           IZ_FI = 2*IZ_CO
               
                           DB_FI(IX_FI-1, 1, IZ_FI-1) = XB_CO(IX_CO, 1, IZ_CO)
                           DB_FI(IX_FI  , 1, IZ_FI-1) = XB_CO(IX_CO, 1, IZ_CO)
                           DB_FI(IX_FI-1, 1, IZ_FI  ) = XB_CO(IX_CO, 1, IZ_CO)
                           DB_FI(IX_FI  , 1, IZ_FI  ) = XB_CO(IX_CO, 1, IZ_CO)
               
                        ENDDO
                     ENDDO
               
                  !!!----------------- 3D -------------------
                  CASE (NSCARC_DIMENSION_THREE)
                     
                     DO IZ_CO = 1, NZ_CO
                        DO IY_CO = 1, NY_CO
                           DO IX_CO = 1, NX_CO
               
                              IX_FI = 2*IX_CO
                              IY_FI = 2*IY_CO
                              IZ_FI = 2*IZ_CO
               
                              DB_FI(IX_FI-1, IY_FI-1, IZ_FI-1) = XB_CO(IX_CO, IY_CO, IZ_CO)
                              DB_FI(IX_FI  , IY_FI-1, IZ_FI-1) = XB_CO(IX_CO, IY_CO, IZ_CO)
                              DB_FI(IX_FI-1, IY_FI  , IZ_FI-1) = XB_CO(IX_CO, IY_CO, IZ_CO)
                              DB_FI(IX_FI  , IY_FI  , IZ_FI-1) = XB_CO(IX_CO, IY_CO, IZ_CO)
                              DB_FI(IX_FI-1, IY_FI-1, IZ_FI  ) = XB_CO(IX_CO, IY_CO, IZ_CO)
                              DB_FI(IX_FI  , IY_FI-1, IZ_FI  ) = XB_CO(IX_CO, IY_CO, IZ_CO)
                              DB_FI(IX_FI-1, IY_FI  , IZ_FI  ) = XB_CO(IX_CO, IY_CO, IZ_CO)
                              DB_FI(IX_FI  , IY_FI  , IZ_FI  ) = XB_CO(IX_CO, IY_CO, IZ_CO)
               
                           ENDDO
                        ENDDO
                     ENDDO
                        
               END SELECT SELECT_BANDED_DIMENSION

            ENDDO
      
         !!!------------------------- Geometric multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_ALGEBRAIC)
            WRITE(*,*) 'No banded restriction for algebraic multigrid available, stopping program!'
            STOP

      END SELECT SELECT_BANDED_MULTIGRID

      
   !!!----------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      SELECT_COMPACT_MULTIGRID: SELECT CASE (TYPE_MULTIGRID)

         !!!------------------------- Geometric multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_GEOMETRIC)

            DO NM = NMESHES_MIN, NMESHES_MAX
         
               NX_CO => SCARC(NM)%COMPACT(NL_CO)%NX
               NY_CO => SCARC(NM)%COMPACT(NL_CO)%NY
               NZ_CO => SCARC(NM)%COMPACT(NL_CO)%NZ
         
               NX_FI = 2*NX_CO
               NY_FI = 2*NY_CO
               NZ_FI = 2*NZ_CO
   
               XC_CO  => POINT_TO_CVECTOR(NVECTOR_CO, NM, NL_CO)
               DC_FI  => POINT_TO_CVECTOR(NVECTOR_FI, NM, NL_FI)
   
               SELECT_COMPACT_DIMENSION: SELECT CASE (TYPE_DIMENSION)
               
                  !!!----------------- 2D -------------------
                  CASE (NSCARC_DIMENSION_TWO)
               
                     DO IZ_CO = 1, NZ_CO
                        DO IX_CO = 1, NX_CO
               
                           IX_FI = 2*IX_CO
                           IY_FI = 1
                           IZ_FI = 2*IZ_CO
               
                           IC_CO = (IZ_CO-1)*NX_CO + IX_CO
               
                           IC_FI(1) = (IZ_FI-2)*NX_FI + IX_FI - 1
                           IC_FI(2) = (IZ_FI-2)*NX_FI + IX_FI   
                           IC_FI(3) = (IZ_FI-1)*NX_FI + IX_FI - 1
                           IC_FI(4) = (IZ_FI-1)*NX_FI + IX_FI    
               
                           DO I = 1, 4
                              DC_FI(IC_FI(I)) = XC_CO(IC_CO)
                           ENDDO
               
                        ENDDO
                     ENDDO
               
                              
                  !!!----------------- 3D -------------------
                  CASE (NSCARC_DIMENSION_THREE)
                     
                     DO IZ_CO = 1, NZ_CO
                        DO IY_CO = 1, NY_CO
                           DO IX_CO = 1, NX_CO
               
                              IX_FI = 2*IX_CO
                              IY_FI = 2*IY_CO
                              IZ_FI = 2*IZ_CO
               
                              IC_CO    = (IZ_CO-1)*NX_CO*NY_CO + (IY_CO-1)*NX_CO + IX_CO
               
                              IC_FI(1) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI - 1
                              IC_FI(2) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI    
                              IC_FI(3) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI - 1
                              IC_FI(4) = (IZ_FI-2)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI    
                              IC_FI(5) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI - 1
                              IC_FI(6) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-2)*NX_FI + IX_FI    
                              IC_FI(7) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI - 1
                              IC_FI(8) = (IZ_FI-1)*NX_FI*NY_FI + (IY_FI-1)*NX_FI + IX_FI    
               
                              DO I = 1, 8
                                 DC_FI(IC_FI(I)) = XC_CO(IC_CO)
                              ENDDO
               
                           ENDDO
                        ENDDO
                     ENDDO
   
               END SELECT SELECT_COMPACT_DIMENSION

            ENDDO

         !!!------------------------- Algebraic multigrid -----------------------------------------------
         CASE (NSCARC_MULTIGRID_ALGEBRAIC)

            DO NM = NMESHES_MIN, NMESHES_MAX

               XC_CO  => POINT_TO_CVECTOR(NVECTOR_CO, NM, NL_CO)
               DC_FI  => POINT_TO_CVECTOR(NVECTOR_FI, NM, NL_FI)

               NC_FI  => SCARC(NM)%COMPACT(NL_FI)%NC
               NCE_FI => SCARC(NM)%COMPACT(NL_FI)%NCE

               P      => SCARC(NM)%COMPACT(NL_FI)%P
               P_ROW  => SCARC(NM)%COMPACT(NL_FI)%P_ROW
               P_COL  => SCARC(NM)%COMPACT(NL_FI)%P_COL
               P_PTR  => SCARC(NM)%COMPACT(NL_FI)%P_PTR
   
               DO IC = 1, NC_FI
                  AUX = 0.0_EB
                  DO ICOL = P_ROW(IC), P_ROW(IC+1)-1
                     IC_CO = P_COL(ICOL)
                     AUX = XC_CO(IC_CO) * P(ICOL)
                  ENDDO
                  DC_FI(IC) = AUX
               ENDDO
               DO IC = NC_FI+1, NCE_FI
                  DC_FI(IC) = 0.0_EB
               ENDDO
            ENDDO
            
      END SELECT SELECT_COMPACT_MULTIGRID

END SELECT SELECT_SYSTEM

END SUBROUTINE SCARC_PROLONGATION



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Finalize data - banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_FINISH_SOLVER(NL)
INTEGER, INTENT(IN) :: NL
INTEGER :: NM, I, J, K, IC
REAL(EB), POINTER, DIMENSION(:,:,:) :: HP
TYPE (MESH_TYPE), POINTER :: M
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

SELECT CASE (TYPE_SYSTEM)
 
   !!!----------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         M  => MESHES(NM)
         SB => SCARC(NM)%BANDED(NL)
      
         IF (PREDICTOR) THEN
            HP => M%H
         ELSE
            HP => M%HS
         ENDIF
      
         !!! Overwrite internal values of H or HS by corresponding data of X
         HP(1:M%IBAR, 1:M%JBAR, 1:M%KBAR) = SB%X(1:M%IBAR, 1:M%JBAR, 1:M%KBAR)
        
      ENDDO 
      
   !!!----------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         M  => MESHES(NM)
         SC => SCARC(NM)%COMPACT(NL)
      
         IF (PREDICTOR) THEN
            HP => M%H
         ELSE
            HP => M%HS
         ENDIF

         DO K = 1, M%KBAR
            DO J = 1, M%JBAR
               DO I = 1, M%IBAR
                  IC = (K-1) * M%IBAR * M%JBAR + (J-1) * M%IBAR + I
                  HP(I, J, K) = SC%X(IC)
               ENDDO
            ENDDO
         ENDDO
      
      ENDDO

END SELECT

END SUBROUTINE SCARC_FINISH_SOLVER


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Set correct boundary values at external and internal boundaries
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UPDATE_GHOSTCELLS(NL)
INTEGER, INTENT(IN) :: NL
INTEGER :: NM, IW, IOR0, IXG, IYG, IZG, IXW, IYW, IZW
REAL(EB), POINTER, DIMENSION(:,:,:) :: HP=>NULL()
TYPE (MESH_TYPE), POINTER :: M
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC

!!!----------------------------------------------------------------------------------------------------
!!! Adjust ghost values along external boundaries according to boundary arrays BXS, BXF, ...
!!!----------------------------------------------------------------------------------------------------
SELECT CASE (TYPE_SYSTEM)
 
   !!!
   !!! Banded system
   !!!
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         !!! point to correct pressure vector on mesh 'NM'
         M  => MESHES(NM)
         SB => SCARC(NM)%BANDED(NL)

         IF (PREDICTOR) THEN
            HP => M%H
         ELSE
            HP => M%HS
         ENDIF
         
         !!! compute ghost cell values
         WALLCELL_BANDED_LOOP: DO IW = 1, SB%NW
         
            IXG = SB%WALL(IW)%IXG
            IYG = SB%WALL(IW)%IYG
            IZG = SB%WALL(IW)%IZG
         
            IXW = SB%WALL(IW)%IXW
            IYW = SB%WALL(IW)%IYW
            IZW = SB%WALL(IW)%IZW
         
            IOR0 = SB%WALL(IW)%IOR
         
            SELECT CASE (IOR0)
               CASE ( 1)
                  IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BXS(IYW,IZW)
                  ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) - DXI *M%BXS(IYW,IZW)
                  ENDIF
               CASE (-1)
                  IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BXF(IYW,IZW)
                  ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) + DXI *M%BXF(IYW,IZW)
                  ENDIF
               CASE ( 2)
                  IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BYS(IXW,IZW)
                  ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) - DETA *M%BYS(IXW,IZW)
                  ENDIF
               CASE (-2)
                  IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BYF(IXW,IZW)
                  ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) + DETA *M%BYF(IXW,IZW)
                  ENDIF
               CASE ( 3)
                  IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BZS(IXW,IYW)
                  ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) - DZETA *M%BZS(IXW,IYW)
                  ENDIF
               CASE (-3)
                  IF (SB%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BZF(IXW,IYW)
                  ELSE IF (SB%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) + DZETA *M%BZF(IXW,IYW)
                  ENDIF
            END SELECT
         ENDDO WALLCELL_BANDED_LOOP
         
      ENDDO

   !!!
   !!! Compact system
   !!!
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         !!! point to correct pressure vector on mesh 'NM'
         M  => MESHES(NM)
         SC => SCARC(NM)%COMPACT(NL)

         IF (PREDICTOR) THEN
            HP => M%H
         ELSE
            HP => M%HS
         ENDIF
         
         !!! compute ghost cell values
         WALLCELL_COMPACT_LOOP: DO IW = 1, SC%NW
         
            IXG = SC%WALL(IW)%IXG
            IYG = SC%WALL(IW)%IYG
            IZG = SC%WALL(IW)%IZG
         
            IXW = SC%WALL(IW)%IXW
            IYW = SC%WALL(IW)%IYW
            IZW = SC%WALL(IW)%IZW
         
            IOR0 = SC%WALL(IW)%IOR
         
            SELECT CASE (IOR0)
               CASE ( 1)
                  IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BXS(IYW,IZW)
                  ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) - DXI *M%BXS(IYW,IZW)
                  ENDIF
               CASE (-1)
                  IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BXF(IYW,IZW)
                  ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) + DXI *M%BXF(IYW,IZW)
                  ENDIF
               CASE ( 2)
                  IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BYS(IXW,IZW)
                  ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) - DETA *M%BYS(IXW,IZW)
                  ENDIF
               CASE (-2)
                  IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BYF(IXW,IZW)
                  ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) + DETA *M%BYF(IXW,IZW)
                  ENDIF
               CASE ( 3)
                  IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BZS(IXW,IYW)
                  ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) - DZETA *M%BZS(IXW,IYW)
                  ENDIF
               CASE (-3)
                  IF (SC%WALL(IW)%BTYPE==DIRICHLET) THEN
                     HP(IXG,IYG,IZG) = -HP(IXW,IYW,IZW) + 2.0_EB * M%BZF(IXW,IYW)
                  ELSE IF (SC%WALL(IW)%BTYPE==NEUMANN) THEN
                     HP(IXG,IYG,IZG) =  HP(IXW,IYW,IZW) + DZETA *M%BZF(IXW,IYW)
                  ENDIF
            END SELECT
         ENDDO WALLCELL_COMPACT_LOOP
         
      ENDDO

END SELECT

!!!---------------------------------------------------------------------------------------------------
!!! Perform data exchange to achieve consistency of ghost values along internal boundaries 
!!!---------------------------------------------------------------------------------------------------
IF (NMESHES > 1) CALL SCARC_EXCHANGE(NSCARC_EXCHANGE_BDRY, NL)

END SUBROUTINE SCARC_UPDATE_GHOSTCELLS


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!  Perform data exchange corresponding to requested exchange type (call receive and send-routines)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_EXCHANGE (NTYPE, NL)
INTEGER, INTENT(IN):: NTYPE, NL

NREQ_SCARC    = 0
TYPE_EXCHANGE = NTYPE

CALL SCARC_RECEIVE(NL)
CALL SCARC_SEND(NL)

END SUBROUTINE SCARC_EXCHANGE
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!  Receive data from neighbors (corresponds to POST_RECEIVES)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_RECEIVE (NL)
INTEGER, INTENT(IN) :: NL
INTEGER :: NM, NOM, IERR, NLEN, IPTR, IW, IBUF(10)
TYPE (SCARC_TYPE)         , POINTER ::  S
TYPE (OSCARC_TYPE)        , POINTER ::  OS
TYPE ( SCARC_BANDED_TYPE) , POINTER ::  SB, SOB
TYPE ( SCARC_COMPACT_TYPE), POINTER ::  SC, SOC
TYPE (OSCARC_BANDED_TYPE) , POINTER ::  OSB
TYPE (OSCARC_COMPACT_TYPE), POINTER ::  OSC

IERR=0
RECEIVE_MESH_LOOP: DO NM = NMESHES_MIN, NMESHES_MAX
   RECEIVE_OMESH_LOOP: DO NOM = 1, NMESHES
    
      SNODE = PROCESS(NOM)
      IF (PROCESS(NM)==SNODE) CYCLE RECEIVE_OMESH_LOOP

      S   => SCARC(NM)                            ! corresponds to M
      OS  => SCARC(NM)%OSCARC(NOM)                ! corresponds to M3

      IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE RECEIVE_OMESH_LOOP

      SELECT_EXCHANGE_TYPE: SELECT CASE (TYPE_EXCHANGE)

         !!!-------------------------------------------------------------------------------------------
         !!! Allocate communication buffer for receiving data
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_ALLOC_REAL)

            IF (OS%NIC_R > 0) THEN
               SELECT CASE (TYPE_SYSTEM)
                  CASE (NSCARC_SYSTEM_BANDED)
                     SB => S%BANDED(NLEVEL_MIN)
                     NLEN = MAX(OS%NIC_R, OS%NIC_S)*SB%NLAYER*NSCARC_COUPLING_MAX*2+10
                  CASE (NSCARC_SYSTEM_COMPACT)
                     SC => S%COMPACT(NLEVEL_MIN)
                     NLEN = MAX(OS%NIC_R, OS%NIC_S)*TYPE_LAYER*NSCARC_COUPLING_MAX*2+10
               END SELECT
               ALLOCATE (OS%RECV_REAL(NLEN))
               OS%RECV_REAL = 0.0_EB
            ENDIF

         !!!-------------------------------------------------------------------------------------------
         !!! Initialize communication structures for the receiving of data
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_ALLOC_INT)

            SELECT CASE (TYPE_SYSTEM)
               CASE (NSCARC_SYSTEM_BANDED)
                  OSB => OS%BANDED(NL)
                  IF (USE_MPI) THEN
                     NREQ_SCARC = NREQ_SCARC+1
                     CALL MPI_IRECV(IBUF(1:2),2,MPI_INTEGER,SNODE, &
                                    TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
                  ELSE                         
                     OSB%NW  = SCARC(NOM)%BANDED(NL)%NW
                     OSB%NWS = SCARC(NOM)%OSCARC(NM)%BANDED(NL)%NWS
                  ENDIF
               CASE (NSCARC_SYSTEM_COMPACT)
                  OSC => OS%COMPACT(NL)
                  IF (USE_MPI) THEN
                     NREQ_SCARC = NREQ_SCARC+1
                     CALL MPI_IRECV(IBUF(1:2),2,MPI_INTEGER,SNODE, &
                                    TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
                  ELSE                         
                     OSC%NW  = SCARC(NOM)%COMPACT(NL)%NW
                     OSC%NWS = SCARC(NOM)%OSCARC(NM)%COMPACT(NL)%NWS
                  ENDIF
            END SELECT

         !!!-------------------------------------------------------------------------------------------
         !!! Initialize communication structures for the receiving of data
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_WALL)


            SELECT CASE (TYPE_SYSTEM)
               CASE (NSCARC_SYSTEM_BANDED)
                  OSB => OS%BANDED(NL)
                  !IF (NL/=NLEVEL_MIN) THEN  ! for lower levels get neighboring WALL's
                  IF (USE_MPI) THEN
                     NREQ_SCARC = NREQ_SCARC+1
                     NLEN = 15*OSB%NW + OSB%NWS
                     CALL MPI_IRECV(OS%RECV_INT(1:NLEN),NLEN,MPI_INTEGER,SNODE, &
                                    TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
                     IPTR=1
                     WALL_BANDED_LOOP: DO IW = 1, OSB%NW
                        OSB%WALL(IW)%IXG  = OS%RECV_INT(IPTR    )
                        OSB%WALL(IW)%IYG  = OS%RECV_INT(IPTR + 1)
                        OSB%WALL(IW)%IZG  = OS%RECV_INT(IPTR + 2)
                        OSB%WALL(IW)%IXW  = OS%RECV_INT(IPTR + 3)
                        OSB%WALL(IW)%IYW  = OS%RECV_INT(IPTR + 4)
                        OSB%WALL(IW)%IZW  = OS%RECV_INT(IPTR + 5)
                        OSB%WALL(IW)%IXN1 = OS%RECV_INT(IPTR + 6)
                        OSB%WALL(IW)%IXN2 = OS%RECV_INT(IPTR + 7)
                        OSB%WALL(IW)%IYN1 = OS%RECV_INT(IPTR + 8)
                        OSB%WALL(IW)%IYN2 = OS%RECV_INT(IPTR + 9)
                        OSB%WALL(IW)%IZN1 = OS%RECV_INT(IPTR +10)
                        OSB%WALL(IW)%IZN2 = OS%RECV_INT(IPTR +11)
                        OSB%WALL(IW)%NOM  = OS%RECV_INT(IPTR +12)
                        OSB%WALL(IW)%IOR  = OS%RECV_INT(IPTR +13)
                        OSB%WALL(IW)%NCPL = OS%RECV_INT(IPTR +14)
                        IPTR = IPTR + 15
                     ENDDO WALL_BANDED_LOOP
                  ELSE                         
                     SOB => SCARC(NOM)%BANDED(NL)
                     OSB%WALL(1:OSB%NW)%IXG  = SOB%WALL(1:SOB%NW)%IXG
                     OSB%WALL(1:OSB%NW)%IYG  = SOB%WALL(1:SOB%NW)%IYG
                     OSB%WALL(1:OSB%NW)%IZG  = SOB%WALL(1:SOB%NW)%IZG
                     OSB%WALL(1:OSB%NW)%IXW  = SOB%WALL(1:SOB%NW)%IXW
                     OSB%WALL(1:OSB%NW)%IYW  = SOB%WALL(1:SOB%NW)%IYW
                     OSB%WALL(1:OSB%NW)%IZW  = SOB%WALL(1:SOB%NW)%IZW
                     OSB%WALL(1:OSB%NW)%IXN1 = SOB%WALL(1:SOB%NW)%IXN1
                     OSB%WALL(1:OSB%NW)%IYN1 = SOB%WALL(1:SOB%NW)%IYN1
                     OSB%WALL(1:OSB%NW)%IZN1 = SOB%WALL(1:SOB%NW)%IZN1
                     OSB%WALL(1:OSB%NW)%IXN2 = SOB%WALL(1:SOB%NW)%IXN2
                     OSB%WALL(1:OSB%NW)%IYN2 = SOB%WALL(1:SOB%NW)%IYN2
                     OSB%WALL(1:OSB%NW)%IZN2 = SOB%WALL(1:SOB%NW)%IZN2
                     OSB%WALL(1:OSB%NW)%IOR  = SOB%WALL(1:SOB%NW)%IOR
                     OSB%WALL(1:OSB%NW)%NOM  = SOB%WALL(1:SOB%NW)%NOM
                  ENDIF
               CASE (NSCARC_SYSTEM_COMPACT)
                  OSC => OS%COMPACT(NL)
                  IF (USE_MPI) THEN
                     NREQ_SCARC = NREQ_SCARC+1
                     NLEN = 15*OSC%NW + OSC%NWS
                     CALL MPI_IRECV(OS%RECV_INT(1:NLEN),NLEN,MPI_INTEGER,SNODE, &
                                    TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
                  ELSE                      
                     SOC => SCARC(NOM)%COMPACT(NL)
                     OSC%WALL(1:OSC%NW)%IXG  = SOC%WALL(1:SOC%NW)%IXG
                     OSC%WALL(1:OSC%NW)%IYG  = SOC%WALL(1:SOC%NW)%IYG
                     OSC%WALL(1:OSC%NW)%IZG  = SOC%WALL(1:SOC%NW)%IZG
                     OSC%WALL(1:OSC%NW)%IXW  = SOC%WALL(1:SOC%NW)%IXW
                     OSC%WALL(1:OSC%NW)%IYW  = SOC%WALL(1:SOC%NW)%IYW
                     OSC%WALL(1:OSC%NW)%IZW  = SOC%WALL(1:SOC%NW)%IZW
                     OSC%WALL(1:OSC%NW)%IXN1 = SOC%WALL(1:SOC%NW)%IXN1
                     OSC%WALL(1:OSC%NW)%IYN1 = SOC%WALL(1:SOC%NW)%IYN1
                     OSC%WALL(1:OSC%NW)%IZN1 = SOC%WALL(1:SOC%NW)%IZN1
                     OSC%WALL(1:OSC%NW)%IXN2 = SOC%WALL(1:SOC%NW)%IXN2
                     OSC%WALL(1:OSC%NW)%IYN2 = SOC%WALL(1:SOC%NW)%IYN2
                     OSC%WALL(1:OSC%NW)%IZN2 = SOC%WALL(1:SOC%NW)%IZN2
                     OSC%WALL(1:OSC%NW)%IOR  = SOC%WALL(1:SOC%NW)%IOR
                     OSC%WALL(1:OSC%NW)%NOM  = SOC%WALL(1:SOC%NW)%NOM
                     OSC%WALL(1:OSC%NW)%NCPL = SOC%WALL(1:SOC%NW)%NCPL
                     DO IW=1,OSC%NW   
                        OSC%WALL(IW)%ICN(1:OSC%WALL(IW)%NCPL) = SOC%WALL(IW)%ICN(1:SOB%WALL(IW)%NCPL)
                     ENDDO
                     IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO .AND. &
                               TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN
                        DO IW=1,OSC%NW   
                           OSC%WALL(IW)%ICN2(1:OSC%WALL(IW)%NCPL) = SOC%WALL(IW)%ICN2(1:SOB%WALL(IW)%NCPL)
                        ENDDO
                     ENDIF
                  ENDIF
            END SELECT
   
         !!!-------------------------------------------------------------------------------------------
         !!! Exchange information about neighboring grid dimensions
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_GRID)

            OSC => OS%COMPACT(NL)
            IF (USE_MPI) THEN
               NREQ_SCARC = NREQ_SCARC+1
               CALL MPI_IRECV(OS%RECV_REAL(1),5,MPI_DOUBLE_PRECISION,SNODE, &
                              TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
            ELSE
               SOC => SCARC(NOM)%COMPACT(NL)
               OSC%NX = SOC%NX
               OSC%NY = SOC%NY
               OSC%NZ = SOC%NZ
               OSC%NC = SOC%NC
               OSC%NW = SOC%NW
            ENDIF

         !!!-------------------------------------------------------------------------------------------
         !!! Exchange number of neighboring cells for AMG method (compact type only)
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_SIZE_MATRIXC)

            OSC => OS%COMPACT(NL)
            IF (USE_MPI) THEN
               NREQ_SCARC = NREQ_SCARC+1
               CALL MPI_IRECV(OS%RECV_REAL(1),1,MPI_DOUBLE_PRECISION,SNODE, &
                              TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
               OSC%NA  = OS%RECV_REAL(1)
            ELSE
               SOC     => SCARC(NOM)%COMPACT(NL)
               OSC%NA  =  SCARC(NOM)%OSCARC(NM)%COMPACT(NL)%NA0
            ENDIF


         !!!-------------------------------------------------------------------------------------------
         !!! Exchange number of neighboring cells for AMG method (compact type only)
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_SIZE_TRANSFERC)

            OSC => OS%COMPACT(NL)
            IF (USE_MPI) THEN
               NREQ_SCARC = NREQ_SCARC+1
               CALL MPI_IRECV(OS%RECV_REAL(1),9,MPI_DOUBLE_PRECISION,SNODE, &
                              TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
               OSC%NC  = OS%RECV_REAL(1)
               OSC%NW  = OS%RECV_REAL(2)
               OSC%NCE = OS%RECV_REAL(3)
               OSC%NW  = OS%RECV_REAL(4)
               OSC%NCCI= OS%RECV_REAL(5)
               OSC%NP  = OS%RECV_REAL(6)
               OSC%NR  = OS%RECV_REAL(7)
               OSC%NCC = OS%RECV_REAL(8)
               OSC%NCF = OS%RECV_REAL(9)
            ELSE
               SOC    => SCARC(NOM)%COMPACT(NL)
               OSC%NC  =  SCARC(NOM)%COMPACT(NL)%NC
               OSC%NW  =  SCARC(NOM)%COMPACT(NL)%NW
               OSC%NCE =  SCARC(NOM)%COMPACT(NL)%NCE
               OSC%NW  =  SCARC(NOM)%COMPACT(NL)%NW
               OSC%NCCI=  SCARC(NOM)%COMPACT(NL)%NCCI
               OSC%NP  =  SCARC(NOM)%OSCARC(NM)%COMPACT(NL)%NP0
               OSC%NR  =  SCARC(NOM)%OSCARC(NM)%COMPACT(NL)%NR0
               OSC%NCC =  SCARC(NOM)%OSCARC(NM)%COMPACT(NL)%NCC0
               OSC%NCF =  SCARC(NOM)%OSCARC(NM)%COMPACT(NL)%NCF0
            ENDIF


         !!!-------------------------------------------------------------------------------------------
         !!! Perform exchanges for 
         !!!    - internal values for matrix-vector multiplication 
         !!!    - internal boundariy values
         !!!    - internal subdiagonal matrix values
         !!!    - internal subdiagonal or ghost matrix values
         !!!    - internal measure/celltype values
         !!!-------------------------------------------------------------------------------------------
         CASE DEFAULT

            NREQ_SCARC = NREQ_SCARC+1
            IF (USE_MPI) CALL MPI_IRECV(OS%RECV_REAL(1),SIZE(OS%RECV_REAL),MPI_DOUBLE_PRECISION,&
                                        SNODE,TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)

      END SELECT SELECT_EXCHANGE_TYPE
   ENDDO RECEIVE_OMESH_LOOP
ENDDO RECEIVE_MESH_LOOP

END SUBROUTINE SCARC_RECEIVE
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Send data to neighbors (corresponds to MESH_EXCHANGE)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SEND (NL)
INTEGER, INTENT(IN) :: NL
INTEGER :: NM, NOM
INTEGER :: IERR, IW, IPTR, ICPL
INTEGER :: NLEN, IBUF(10)
INTEGER, POINTER:: NW, NX, NY, NC
REAL(EB), POINTER, DIMENSION(:)    :: BUF_REAL
INTEGER,  POINTER, DIMENSION(:)    :: BUF_INT
TYPE (SCARC_TYPE)         , POINTER :: S 
TYPE (SCARC_BANDED_TYPE)  , POINTER :: SB, SOB
TYPE (SCARC_COMPACT_TYPE) , POINTER :: SC, SOC
TYPE (OSCARC_TYPE)        , POINTER :: OS, OSO
TYPE (OSCARC_BANDED_TYPE) , POINTER :: OSB
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSC, SCO
TYPE (SCARC_WALL_TYPE)    , DIMENSION(:), POINTER :: WALL 

IERR = 0

EXCHANGE_SEND_LOOP1: DO NM = NMESHES_MIN, NMESHES_MAX

   IF (PROCESS(NM)/=MYID)  CYCLE EXCHANGE_SEND_LOOP1

   EXCHANGE_RECV_LOOP1: DO NOM = 1, NMESHES
    
      SNODE = PROCESS(NOM)
      RNODE = PROCESS(NM)

      S   => SCARC(NM)                           ! corresponds to M
      OS  => SCARC(NM)%OSCARC(NOM)               ! corresponds to M3

      IF (OS%NICMAX_S == 0 .AND. OS%NICMAX_R == 0) CYCLE EXCHANGE_RECV_LOOP1

      SELECT_EXCHANGE: SELECT CASE (TYPE_EXCHANGE)

         !!!-------------------------------------------------------------------------------------------
         !!! Allocate communication buffer for sending of data
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_ALLOC_REAL)

            IF (OS%NIC_R > 0) THEN
               SELECT CASE (TYPE_SYSTEM)
                  CASE (NSCARC_SYSTEM_BANDED)
                     SB => S%BANDED(NLEVEL_MIN)
                     NLEN = MAX(OS%NIC_R, OS%NIC_S)*SB%NLAYER*NSCARC_COUPLING_MAX*2+10
                  CASE (NSCARC_SYSTEM_COMPACT)
                     SC => S%COMPACT(NLEVEL_MIN)
                     NLEN = MAX(OS%NIC_R, OS%NIC_S)*TYPE_LAYER*NSCARC_COUPLING_MAX*2+10
               END SELECT
               ALLOCATE (OS%SEND_REAL(NLEN))
               OS%SEND_REAL = 0.0_EB
            ENDIF

         !!!-------------------------------------------------------------------------------------------
         !!! Exchange wall related data
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_ALLOC_INT)

            SELECT CASE (TYPE_SYSTEM)
               CASE (NSCARC_SYSTEM_BANDED)
                  SB  =>  S%BANDED(NL)     
                  OSB => OS%BANDED(NL)    
                  IF (RNODE /= SNODE) THEN
                     IBUF(1)= SB%NW
                     IBUF(2)=OSB%NWS
                     IF (USE_MPI) THEN
                        NREQ_SCARC = NREQ_SCARC+1
                        CALL MPI_ISEND(IBUF(1:2),2,MPI_INTEGER,SNODE, &
                                      TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
                     ENDIF
                  ELSE
                     OSB%NW  = SCARC(NOM)%BANDED(NL)%NW
                     OSB%NWS = SCARC(NOM)%OSCARC(NM)%BANDED(NL)%NWS
                  ENDIF
               CASE (NSCARC_SYSTEM_COMPACT)
                  IF (RNODE /= SNODE) THEN
                     SC  =>  S%COMPACT(NL)     
                     OSC => OS%COMPACT(NL)     
                     IBUF(1)= SC%NW
                     IBUF(2)=OSC%NWS
                     IF (USE_MPI) THEN
                        NREQ_SCARC = NREQ_SCARC+1
                        CALL MPI_ISEND(IBUF(1:2),2,MPI_INTEGER,SNODE, &
                                      TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
                     ENDIF
                  ENDIF
            END SELECT 

         !!!-------------------------------------------------------------------------------------------
         !!! Exchange wall related data
         !!!-------------------------------------------------------------------------------------------
         CASE (NSCARC_EXCHANGE_WALL)

         ! on max level   : take M%WALL from neighbors (ScaRC pointers already defined, nothing to do ...)
         ! on lover levels: send own WALL to neighbors
         SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

            CASE (NSCARC_SYSTEM_BANDED)
               IF (RNODE /= SNODE) THEN
                  SB  =>  S%BANDED(NL)                       ! corresponds to M  for the level 'NL'
                  OSB => OS%BANDED(NL)                       ! corresponds to M3 for the level 'NL'
                  IPTR=1
                  DO IW = 1, SB%NW
                     OS%SEND_INT(IPTR   )=SB%WALL(IW)%IXG
                     OS%SEND_INT(IPTR+ 1)=SB%WALL(IW)%IYG
                     OS%SEND_INT(IPTR+ 2)=SB%WALL(IW)%IZG
                     OS%SEND_INT(IPTR+ 3)=SB%WALL(IW)%IXW
                     OS%SEND_INT(IPTR+ 4)=SB%WALL(IW)%IYW
                     OS%SEND_INT(IPTR+ 5)=SB%WALL(IW)%IZW
                     OS%SEND_INT(IPTR+ 6)=SB%WALL(IW)%IXN1
                     OS%SEND_INT(IPTR+ 7)=SB%WALL(IW)%IXN2
                     OS%SEND_INT(IPTR+ 8)=SB%WALL(IW)%IYN1
                     OS%SEND_INT(IPTR+ 9)=SB%WALL(IW)%IYN2
                     OS%SEND_INT(IPTR+10)=SB%WALL(IW)%IZN1
                     OS%SEND_INT(IPTR+11)=SB%WALL(IW)%IZN2
                     OS%SEND_INT(IPTR+12)=SB%WALL(IW)%NOM
                     OS%SEND_INT(IPTR+13)=SB%WALL(IW)%IOR
                     OS%SEND_INT(IPTR+14)=SB%WALL(IW)%NCPL
                     IPTR = IPTR + 15
                  ENDDO
                  IF (USE_MPI) THEN
                     NREQ_SCARC = NREQ_SCARC+1
                     NLEN = 15*OSB%NW+OSB%NWS
                     CALL MPI_ISEND(OS%SEND_INT(1:NLEN),NLEN,MPI_INTEGER,SNODE, &
                                   TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
                  ENDIF
               ENDIF

            CASE (NSCARC_SYSTEM_COMPACT)
               IF (RNODE /= SNODE) THEN
                  SC  =>  S%COMPACT(NL)                       ! corresponds to M  for the level 'NL'
                  OSC => OS%COMPACT(NL)                       ! corresponds to M3 for the level 'NL'
                  IPTR=1
                  DO IW = 1, SC%NW
                     OS%SEND_INT(IPTR   )=SC%WALL(IW)%IXG
                     OS%SEND_INT(IPTR+ 1)=SC%WALL(IW)%IYG
                     OS%SEND_INT(IPTR+ 2)=SC%WALL(IW)%IZG
                     OS%SEND_INT(IPTR+ 3)=SC%WALL(IW)%IXW
                     OS%SEND_INT(IPTR+ 4)=SC%WALL(IW)%IYW
                     OS%SEND_INT(IPTR+ 5)=SC%WALL(IW)%IZW
                     OS%SEND_INT(IPTR+ 6)=SC%WALL(IW)%IXN1
                     OS%SEND_INT(IPTR+ 7)=SC%WALL(IW)%IXN2
                     OS%SEND_INT(IPTR+ 8)=SC%WALL(IW)%IYN1
                     OS%SEND_INT(IPTR+ 9)=SC%WALL(IW)%IYN2
                     OS%SEND_INT(IPTR+10)=SC%WALL(IW)%IZN1
                     OS%SEND_INT(IPTR+11)=SC%WALL(IW)%IZN2
                     OS%SEND_INT(IPTR+12)=SC%WALL(IW)%NOM
                     OS%SEND_INT(IPTR+13)=SC%WALL(IW)%IOR
                     OS%SEND_INT(IPTR+14)=SC%WALL(IW)%NCPL
                     IPTR = IPTR + 15
                     IF (SC%WALL(IW)%NOM == NOM) THEN
                        DO ICPL=1,SC%WALL(IW)%NCPL
                           OS%SEND_INT(IPTR)=SC%WALL(IW)%ICN(ICPL)
                           IPTR = IPTR + 1
                        ENDDO
                        IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO .AND. &
                           TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN
                           DO ICPL=1,SC%WALL(IW)%NCPL
                              OS%SEND_INT(IPTR)=SC%WALL(IW)%ICN(ICPL)
                              IPTR = IPTR + 1
                           ENDDO
                        ENDIF
                     ENDIF
                  ENDDO
                  NREQ_SCARC = NREQ_SCARC+1
                  NLEN = 15*OSC%NW+OSC%NWS
                  CALL MPI_ISEND(OS%SEND_INT(1:NLEN),NLEN,MPI_INTEGER,SNODE, &
                                 TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
               ENDIF

         END SELECT SELECT_SYSTEM


      !!!-------------------------------------------------------------------------------------------
      !!! Exchange neighboring grid information
      !!!-------------------------------------------------------------------------------------------
      CASE (NSCARC_EXCHANGE_GRID) 

         IF (RNODE /= SNODE) THEN
            SC  =>  S%COMPACT(NL)
            OSC => OS%COMPACT(NL)
            NREQ_SCARC = NREQ_SCARC+1
            IBUF(1)=SC%NX
            IBUF(2)=SC%NY
            IBUF(3)=SC%NZ
            IBUF(4)=SC%NC
            IBUF(5)=SC%NW
            IF (USE_MPI) CALL MPI_ISEND(IBUF(1),5,MPI_INTEGER,SNODE, &
                                        TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
         ENDIF

      !!!-------------------------------------------------------------------------------------------
      !!! Exchange size of overlapped parts for system matrix
      !!!-------------------------------------------------------------------------------------------
      CASE (NSCARC_EXCHANGE_SIZE_MATRIXB) 

         IF (RNODE /= SNODE) THEN
            SB  =>  S%BANDED(NL)
            OSB => OS%BANDED(NL)
            NREQ_SCARC = NREQ_SCARC+1
            IBUF(1) = OSB%NA0
            IF (USE_MPI) CALL MPI_ISEND(IBUF(1),1,MPI_INTEGER,SNODE, &
                                        TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
         ENDIF

      !!!-------------------------------------------------------------------------------------------
      !!! Exchange size of overlapped parts for system matrix
      !!!-------------------------------------------------------------------------------------------
      CASE (NSCARC_EXCHANGE_SIZE_MATRIXC) 

         IF (RNODE /= SNODE) THEN
            SC  =>  S%COMPACT(NL)
            OSC => OS%COMPACT(NL)
            NREQ_SCARC = NREQ_SCARC+1
            IBUF(1) = OSC%NA0
            IF (USE_MPI) CALL MPI_ISEND(IBUF(1),1,MPI_INTEGER,SNODE, &
                                        TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
         ENDIF

      !!!-------------------------------------------------------------------------------------------
      !!! Exchange number of neighboring cells for AMG method (compact type only)
      !!!-------------------------------------------------------------------------------------------
      CASE (NSCARC_EXCHANGE_SIZE_TRANSFERC) 

         IF (RNODE /= SNODE) THEN
            SC  =>  S%COMPACT(NL)
            OSC => OS%COMPACT(NL)
            NREQ_SCARC = NREQ_SCARC+1
            IBUF(1) = SC%NC
            IBUF(2) = SC%NW
            IBUF(3) = SC%NCE
            IBUF(4) = SC%NW
            IBUF(5) = SC%NCCI
            IBUF(6) = OSC%NP0
            IBUF(7) = OSC%NR0
            IBUF(8) = OSC%NCC0
            IBUF(9) = OSC%NCF0
            IF (USE_MPI) CALL MPI_ISEND(IBUF(1:9),9,MPI_INTEGER,SNODE, &
                                        TAG_SCARC,MPI_COMM_WORLD,REQ_SCARC(NREQ_SCARC),IERR)
         ENDIF

      !!!-------------------------------------------------------------------------------------------
      !!! Exchange data along internal boundaries corresponding to requested exchange type
      !!!-------------------------------------------------------------------------------------------
      CASE DEFAULT

         NLEN = 0
         BUF_REAL => OS%SEND_REAL

         SELECT_SYSTEM2: SELECT CASE(TYPE_SYSTEM)

            !!! -------------------------- Banded system  ------------------------------------------
            CASE (NSCARC_SYSTEM_BANDED)

               SB  =>  S%BANDED(NL)                       ! corresponds to M  for the level 'NL'
               OSB => OS%BANDED(NL)                       ! corresponds to M3 for the level 'NL'

               WALL   => OSB%WALL
               NW     => OSB%NW
               NX     => SB%NX
               NY     => SB%NY
               NC     => SB%NC

               SELECT_EXCHANGE_BANDED: SELECT CASE (TYPE_EXCHANGE)

                  CASE (NSCARC_EXCHANGE_VECTOR) 
                     CALL SCARC_PACK_BVECTOR_REAL(BUF_REAL, OSB%WALL, TYPE_VECTOR, NLEN, NW, NM, NL)

                  CASE (NSCARC_EXCHANGE_BDRY) 
                     IF (PREDICTOR) THEN
                        CALL SCARC_PACK_BVECTOR_REAL(BUF_REAL, OSB%WALL, NSCARC_VECTOR_H , NLEN, NW, NM, NL)
                     ELSE
                        CALL SCARC_PACK_BVECTOR_REAL(BUF_REAL, OSB%WALL, NSCARC_VECTOR_HS, NLEN, NW, NM, NL)
                     ENDIF

                  CASE (NSCARC_EXCHANGE_MATRIX) 
                     CALL SCARC_PACK_BMATRIX(BUF_REAL, OSB%WALL, TYPE_MATRIX, NLEN, NW, NM, NL)
            
                  CASE DEFAULT
                     WRITE (*,*) 'BANDED: TYPE_EXCHANGE =',TYPE_EXCHANGE,' NOT ALLOWED,/,STOPPING PROGRAM !'
                     STOP

               END SELECT SELECT_EXCHANGE_BANDED

            !!! -------------------------- Compact system  -----------------------------------------
            CASE (NSCARC_SYSTEM_COMPACT)

               SC  =>  S%COMPACT(NL)                       ! corresponds to M  for the level 'NL'
               OSC => OS%COMPACT(NL)                       ! corresponds to M3 for the level 'NL'

               WALL   => OSC%WALL
               NW     => OSC%NW
               NX     => SC%NX
               NY     => SC%NY
               NC     => SC%NC

               SELECT_EXCHANGE_COMPACT: SELECT CASE (TYPE_EXCHANGE)

                  CASE (NSCARC_EXCHANGE_VECTOR) 
                     CALL SCARC_PACK_CVECTOR_REAL(BUF_REAL, WALL, TYPE_VECTOR, NLEN, NW, NM, NL)
            
                  CASE (NSCARC_EXCHANGE_BDRY) 
                     IF (PREDICTOR) THEN
                        CALL SCARC_PACK_BVECTOR_REAL(BUF_REAL, WALL, NSCARC_VECTOR_H , NLEN, NW, NM, NL)
                     ELSE
                        CALL SCARC_PACK_BVECTOR_REAL(BUF_REAL, WALL, NSCARC_VECTOR_HS, NLEN, NW, NM, NL)
                     ENDIF

                  CASE (NSCARC_EXCHANGE_MATRIX) 
                     CALL SCARC_PACK_CMATRIX(BUF_REAL, WALL, TYPE_MATRIX, NLEN, NW, NM, NOM, NL)
            
                  CASE (NSCARC_EXCHANGE_MEASURE) 
                     CALL SCARC_PACK_CVECTOR_REAL2(BUF_REAL, WALL, NSCARC_VECTOR_MEASURE, NLEN, NW, NM, NL)
            
                  CASE (NSCARC_EXCHANGE_CELLTYPE) 
                     CALL SCARC_PACK_CVECTOR_INT2 (BUF_REAL, WALL, NSCARC_VECTOR_CELLTYPE, NLEN, NW, NM, NL)
      
                  CASE (NSCARC_EXCHANGE_WEIGHTS) 
                     CALL SCARC_PACK_CMATRIX(BUF_REAL, WALL, NSCARC_MATRIX_PROLONGATION, NLEN, NW, NM, NOM, NL)

                  CASE DEFAULT
                     WRITE (*,*) 'COMPACT: TYPE_EXCHANGE =',TYPE_EXCHANGE,' NOT ALLOWED,/,STOPPING PROGRAM !'
                     STOP
         
               END SELECT SELECT_EXCHANGE_COMPACT

          END SELECT SELECT_SYSTEM2

         !!! Finally exchange send buffer with corresponding neighbors
         IF (RNODE/=SNODE) THEN
            NREQ_SCARC=NREQ_SCARC+1
            IF (USE_MPI) CALL MPI_ISEND(BUF_REAL, NLEN, MPI_DOUBLE_PRECISION, SNODE, &
                                        TAG_SCARC, MPI_COMM_WORLD, REQ_SCARC(NREQ_SCARC), IERR)
         ENDIF

      END SELECT SELECT_EXCHANGE

   ENDDO EXCHANGE_RECV_LOOP1

ENDDO EXCHANGE_SEND_LOOP1


!!!----------------------------------------------------------------------------------------------------
!!! Information from Mesh NM is received by Mesh NOM  (NOM receiver, NM sender)
!!!----------------------------------------------------------------------------------------------------
IF (USE_MPI.AND.NREQ_SCARC/=0) CALL MPI_WAITALL(NREQ_SCARC,REQ_SCARC(1:NREQ_SCARC),MPI_STATUS_IGNORE,IERR)


!!!----------------------------------------------------------------------------------------------------
!!! Extract communication data from corresponding RECEIVE-buffers
!!!----------------------------------------------------------------------------------------------------
EXCHANGE_SEND_LOOP2: DO NOM = NMESHES_MIN, NMESHES_MAX

   EXCHANGE_RECV_LOOP2: DO NM=1,NMESHES
    
      SNODE  = PROCESS(NOM)
      RNODE  = PROCESS(NM)

      OSO => SCARC(NOM)%OSCARC(NM)

      EXCHANGE_RECV_IF: IF (OSO%NICMAX_S/=0 .AND. OSO%NICMAX_R/=0) THEN

         IF (RNODE/=SNODE) THEN
            BUF_REAL => OSO%RECV_REAL
         ELSE
            OS => SCARC(NM)%OSCARC(NOM)
            BUF_REAL => OS%SEND_REAL
         ENDIF

         SELECT CASE(TYPE_SYSTEM)

            !!! -------------------------- Banded system  ------------------------------------------
            CASE (NSCARC_SYSTEM_BANDED)

               SOB  => SCARC(NOM)%BANDED(NL)
               OSB  => OSO%BANDED(NL)

               WALL => SOB%WALL
               NX   => SOB%NX
               NY   => SOB%NY
      
               SELECT_EXCHANGE_BANDED2: SELECT CASE (TYPE_EXCHANGE)
      
                  CASE (NSCARC_EXCHANGE_ALLOC_INT) 
                     OSB%NW  = IBUF(1)
                     OSB%NWS = IBUF(2)

                     NLEN = 15*OSB%NW + OSB%NWS
                     ALLOCATE (OSO%RECV_INT(NLEN))
                     OSO%RECV_INT = 0
                     ALLOCATE (OSO%SEND_INT(NLEN))
                     OSO%SEND_INT = 0

                  CASE (NSCARC_EXCHANGE_GRID) 
                     OSB%NX = IBUF(1)
                     OSB%NY = IBUF(2)
                     OSB%NZ = IBUF(3)
                     OSB%NC = IBUF(4)
                     OSB%NW = IBUF(5)

                  CASE (NSCARC_EXCHANGE_VECTOR) 
                     CALL SCARC_UNPACK_BVECTOR_REAL(BUF_REAL, WALL, TYPE_VECTOR, NOM, NL)
     
                  CASE (NSCARC_EXCHANGE_BDRY)
                     IF (PREDICTOR) THEN
                        CALL SCARC_UNPACK_BVECTOR_REAL(BUF_REAL, WALL, NSCARC_VECTOR_H, NOM, NL)
                     ELSE
                        CALL SCARC_UNPACK_BVECTOR_REAL(BUF_REAL, WALL, NSCARC_VECTOR_HS, NOM, NL)
                     ENDIF
      
                  CASE (NSCARC_EXCHANGE_MATRIX)
                     CALL SCARC_UNPACK_BMATRIX(BUF_REAL, WALL, TYPE_MATRIX, NOM, NL)
      
                END SELECT SELECT_EXCHANGE_BANDED2

            !!! -------------------------- Compact system  -----------------------------------------
            CASE (NSCARC_SYSTEM_COMPACT)

               SOC  => SCARC(NOM)%COMPACT(NL)
               OSC  => SCARC(NOM)%OSCARC(NM)%COMPACT(NL)

               WALL => SOC%WALL
               NX   => SOC%NX
               NY   => SOC%NY
      
               SELECT_EXCHANGE_COMPACT2: SELECT CASE (TYPE_EXCHANGE)
      
                  CASE (NSCARC_EXCHANGE_ALLOC_INT) 
                     IF (RNODE/=SNODE) THEN
                        OSC%NW  = IBUF(1)
                        OSC%NWS = IBUF(2)
                     ELSE
                        OSC%NW  = SCARC(NM)%COMPACT(NL)%NW
                        OSC%NWS = SCARC(NM)%OSCARC(NOM)%COMPACT(NL)%NWS
                     ENDIF

                     NLEN = 15*OSC%NW + OSC%NWS
                     ALLOCATE (OSO%RECV_INT(NLEN))
                     OSO%RECV_INT = 0
                     ALLOCATE (OSO%SEND_INT(NLEN))
                     OSO%SEND_INT = 0


                  CASE (NSCARC_EXCHANGE_WALL)
                     IF (RNODE/=SNODE) THEN
                        BUF_INT => OSO%RECV_INT
                        IPTR=1
                        DO IW = 1, OSC%NW
                           OSC%WALL(IW)%IXG  = BUF_INT(IPTR    )
                           OSC%WALL(IW)%IYG  = BUF_INT(IPTR + 1)
                           OSC%WALL(IW)%IZG  = BUF_INT(IPTR + 2)
                           OSC%WALL(IW)%IXW  = BUF_INT(IPTR + 3)
                           OSC%WALL(IW)%IYW  = BUF_INT(IPTR + 4)
                           OSC%WALL(IW)%IZW  = BUF_INT(IPTR + 5)
                           OSC%WALL(IW)%IXN1 = BUF_INT(IPTR + 6)
                           OSC%WALL(IW)%IXN2 = BUF_INT(IPTR + 7)
                           OSC%WALL(IW)%IYN1 = BUF_INT(IPTR + 8)
                           OSC%WALL(IW)%IYN2 = BUF_INT(IPTR + 9)
                           OSC%WALL(IW)%IZN1 = BUF_INT(IPTR +10)
                           OSC%WALL(IW)%IZN2 = BUF_INT(IPTR +11)
                           OSC%WALL(IW)%NOM  = BUF_INT(IPTR +12)
                           OSC%WALL(IW)%IOR  = BUF_INT(IPTR +13)
                           OSC%WALL(IW)%NCPL = BUF_INT(IPTR +14)
                           IPTR = IPTR + 15
                           IF (OSC%WALL(IW)%NOM == NOM) THEN
                              ALLOCATE (OSC%WALL(IW)%ICN(OSC%WALL(IW)%NCPL))
                              DO ICPL=1,OSC%WALL(IW)%NCPL
                                 OSC%WALL(IW)%ICN(ICPL) = BUF_INT(IPTR)
                                 IPTR = IPTR + 1
                              ENDDO
                              IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO .AND. &
                                  TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN
                                 DO ICPL=1,OSC%WALL(IW)%NCPL
                                    OSC%WALL(IW)%ICN2(ICPL) = BUF_INT(IPTR)
                                    IPTR = IPTR + 1
                                 ENDDO
                              ENDIF
                           ENDIF
                        ENDDO
                     ELSE
                        SC => SCARC(NM)%COMPACT(NL)
                        OSC%NW= SCARC(NM)%COMPACT(NL)%NW
                        DO IW = 1, OSC%NW
                        OSC%WALL(IW)%IXG  = SC%WALL(IW)%IXG
                        OSC%WALL(IW)%IYG  = SC%WALL(IW)%IYG
                        OSC%WALL(IW)%IZG  = SC%WALL(IW)%IZG
                        OSC%WALL(IW)%IXW  = SC%WALL(IW)%IXW
                        OSC%WALL(IW)%IYW  = SC%WALL(IW)%IYW
                        OSC%WALL(IW)%IZW  = SC%WALL(IW)%IZW
                        OSC%WALL(IW)%IXN1 = SC%WALL(IW)%IXN1
                        OSC%WALL(IW)%IXN2 = SC%WALL(IW)%IXN2
                        OSC%WALL(IW)%IYN1 = SC%WALL(IW)%IYN1
                        OSC%WALL(IW)%IYN2 = SC%WALL(IW)%IYN2
                        OSC%WALL(IW)%IZN1 = SC%WALL(IW)%IZN1
                        OSC%WALL(IW)%IZN2 = SC%WALL(IW)%IZN2
                        OSC%WALL(IW)%IOR  = SC%WALL(IW)%IOR
                        OSC%WALL(IW)%NOM  = SC%WALL(IW)%NOM
                        OSC%WALL(IW)%ICW  = SC%WALL(IW)%ICW
                        OSC%WALL(IW)%NCPL = SC%WALL(IW)%NCPL
                           IF (OSC%WALL(IW)%NOM /= 0) THEN
                              ALLOCATE(OSC%WALL(IW)%ICN(1:OSC%WALL(IW)%NCPL),STAT=IERR)
                              CALL ChkMemErr('SCARC_SETUP','ICN',IERR)
                              OSC%WALL(IW)%ICN(1:OSC%WALL(IW)%NCPL) = SC%WALL(IW)%ICN(1:SC%WALL(IW)%NCPL)
                           ENDIF
                        ENDDO
                        IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO .AND. &
                            TYPE_MULTIGRID == NSCARC_MULTIGRID_ALGEBRAIC) THEN
                           DO IW=1,OSC%NW   
                              IF (OSC%WALL(IW)%NOM /= 0) THEN
                                 ALLOCATE(OSC%WALL(IW)%ICN2(1:OSC%WALL(IW)%NCPL),STAT=IERR)
                                 CALL ChkMemErr('SCARC_SETUP','ICN2',IERR)
                                 OSC%WALL(IW)%ICN2(1:OSC%WALL(IW)%NCPL) = SC%WALL(IW)%ICN2(1:SC%WALL(IW)%NCPL)
                              ENDIF
                           ENDDO
                        ENDIF
                     ENDIF

                  CASE (NSCARC_EXCHANGE_GRID) 
                     IF (RNODE /= SNODE) THEN
                        OSC%NX = IBUF(1)
                        OSC%NY = IBUF(2)
                        OSC%NZ = IBUF(3)
                        OSC%NC = IBUF(4)
                        OSC%NW = IBUF(5)
                     ELSE
                        SC => SCARC(NM)%COMPACT(NL)
                        OSC%NX =  SC%NX
                        OSC%NY =  SC%NY
                        OSC%NZ =  SC%NZ
                        OSC%NC =  SC%NC
                        OSC%NW =  SC%NW
                     ENDIF

                  CASE (NSCARC_EXCHANGE_SIZE_MATRIXC) 
                     IF (RNODE /= SNODE) THEN
                        OSC%NA = IBUF(1)
                     ELSE
                        OSC%NA = SCARC(NM)%OSCARC(NOM)%COMPACT(NL)%NA0
                     ENDIF

                  CASE (NSCARC_EXCHANGE_SIZE_TRANSFERC) 
                     IF (RNODE /= SNODE) THEN
                        OSC%NC  =  IBUF(1)
                        OSC%NW  =  IBUF(2)
                        OSC%NCE =  IBUF(3)
                        OSC%NW  =  IBUF(4)
                        OSC%NCCI=  IBUF(5)
                        OSC%NP  =  IBUF(6)
                        OSC%NR  =  IBUF(7)
                        OSC%NCC =  IBUF(8)
                        OSC%NCF =  IBUF(9)
                     ELSE
                        SC  => SCARC(NM)%COMPACT(NL)
                        SCO => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
                        OSC%NC  =  SC%NC
                        OSC%NW  =  SC%NW
                        OSC%NCE =  SC%NCE
                        OSC%NCCI=  SC%NCCI
                        OSC%NP  =  SCO%NP0
                        OSC%NR  =  SCO%NR0
                        OSC%NCC =  SCO%NCC0
                        OSC%NCF =  SCO%NCF0
                     ENDIF

                  CASE (NSCARC_EXCHANGE_VECTOR) 
                     CALL SCARC_UNPACK_CVECTOR_REAL(BUF_REAL, WALL, TYPE_VECTOR, NOM, NL)
      
                  CASE (NSCARC_EXCHANGE_BDRY)
                     IF (PREDICTOR) THEN
                        CALL SCARC_UNPACK_BVECTOR_REAL(BUF_REAL, WALL, NSCARC_VECTOR_H, NOM, NL)
                     ELSE
                        CALL SCARC_UNPACK_BVECTOR_REAL(BUF_REAL, WALL, NSCARC_VECTOR_HS, NOM, NL)
                     ENDIF
      
                  CASE (NSCARC_EXCHANGE_MATRIX)
                     CALL SCARC_UNPACK_CMATRIX(BUF_REAL, WALL, TYPE_MATRIX, NOM, NM, NL)
      
                  CASE (NSCARC_EXCHANGE_MEASURE)
                     CALL SCARC_UNPACK_CVECTOR_REAL2(BUF_REAL, WALL, NSCARC_VECTOR_MEASURE, NM, NOM, NL)
      
                  CASE (NSCARC_EXCHANGE_CELLTYPE)
                     CALL SCARC_UNPACK_CVECTOR_INT2 (BUF_REAL, WALL, NSCARC_VECTOR_CELLTYPE, NM, NOM, NL)
      
                  CASE (NSCARC_EXCHANGE_WEIGHTS)
                     CALL SCARC_UNPACK_CMATRIX(BUF_REAL, WALL, NSCARC_MATRIX_PROLONGATION, NOM, NM, NL)
      
                END SELECT SELECT_EXCHANGE_COMPACT2

         END SELECT
      ENDIF EXCHANGE_RECV_IF
   ENDDO EXCHANGE_RECV_LOOP2
ENDDO EXCHANGE_SEND_LOOP2

END SUBROUTINE SCARC_SEND
 
 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Pack send buffer for exchange of internal vector in banded storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PACK_BVECTOR_REAL (SEND_REAL, WALL, NTYPE, NLEN, NW, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(OUT) :: SEND_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER, INTENT(IN)  :: NTYPE, NW, NM, NL
INTEGER, INTENT(OUT) :: NLEN
INTEGER ::  IW, IWW, LL, II, JJ, KK
REAL(EB), POINTER, DIMENSION(:,:,:) :: BVECTOR

BVECTOR => POINT_TO_BVECTOR (NTYPE, NM, NL)

LL  = 0
IWW = 0
PACK_SEND: DO IW=1,NW
   IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND
   DO KK=WALL(IW)%IZN1,WALL(IW)%IZN2
      DO JJ=WALL(IW)%IYN1,WALL(IW)%IYN2
         DO II=WALL(IW)%IXN1,WALL(IW)%IXN2
            IWW = IWW + 1
            SEND_REAL(LL+1) = REAL(IW,EB)
            SEND_REAL(LL+2) = BVECTOR(II,JJ,KK)
            LL = LL+2
         ENDDO
      ENDDO
   ENDDO
ENDDO PACK_SEND
NLEN=2*IWW+1

SEND_REAL(NLEN) = -999.0_EB

END SUBROUTINE SCARC_PACK_BVECTOR_REAL
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Unpack receive buffer for internal update
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UNPACK_BVECTOR_REAL (RECV_REAL, WALL, NTYPE, NM, NL)
REAL (EB), DIMENSION (:)    , INTENT(IN)  :: RECV_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN):: NTYPE, NM, NL
REAL (EB):: ZSUM=0.0_EB
INTEGER IW, LL, ISUM, I, J, K, II, JJ, KK
REAL(EB), POINTER, DIMENSION(:,:,:) :: BVECTOR


BVECTOR => POINT_TO_BVECTOR (NTYPE, NM, NL)

LL = 0
UNPACK_RECV: DO

   IW = NINT(RECV_REAL(LL+1))
   IF (IW==-999) EXIT UNPACK_RECV
   ZSUM=0.0_EB
   DO KK=WALL(IW)%IZN1,WALL(IW)%IZN2
      DO JJ=WALL(IW)%IYN1,WALL(IW)%IYN2
         DO II=WALL(IW)%IXN1,WALL(IW)%IXN2
            ZSUM=ZSUM+RECV_REAL(LL+2)
            LL = LL+2
         ENDDO
      ENDDO
   ENDDO

   ISUM = (WALL(IW)%IXN2-WALL(IW)%IXN1+1) * &
          (WALL(IW)%IYN2-WALL(IW)%IYN1+1) * &
          (WALL(IW)%IZN2-WALL(IW)%IZN1+1)

   I=WALL(IW)%IXG
   J=WALL(IW)%IYG
   K=WALL(IW)%IZG
   BVECTOR(I, J, K) = ZSUM/REAL(ISUM,EB)

ENDDO UNPACK_RECV

END SUBROUTINE SCARC_UNPACK_BVECTOR_REAL


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Pack send buffer for exchange of internal vector in compact storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PACK_CVECTOR_REAL (SEND_REAL, WALL, NTYPE, NLEN, NW, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(OUT) :: SEND_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER, INTENT(IN)  :: NTYPE, NW, NM, NL
INTEGER, INTENT(OUT) :: NLEN
INTEGER ::  IW, IWW, LL, IC, NCPL, ICPL
REAL(EB), POINTER, DIMENSION(:) :: CVECTOR
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC

SC => SCARC(NM)%COMPACT(NL)
CVECTOR => POINT_TO_CVECTOR (NTYPE, NM, NL)

LL  = 0
IWW = 0
PACK_SEND2: DO IW=1,NW
!WRITE(SCARC_LU,*) '========================= IW : ', WALL(IW)%NOM, NM
   IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND2
   NCPL = WALL(IW)%NCPL
!WRITE(SCARC_LU,*) '  NCPL =', NCPL
   DO ICPL = 1, NCPL
      IC = WALL(IW)%ICN(ICPL)
      IWW = IWW + 1
      SEND_REAL(LL+1) = REAL(IW,EB)
      SEND_REAL(LL+2) = CVECTOR(IC)
!WRITE(SCARC_LU,'(a,i4,a,f12.6,3i3)') 'SEND_REAL(',LL+2,')=',SEND_REAL(LL+2), IW, NW, IC
      LL = LL+2
   ENDDO
ENDDO PACK_SEND2
NLEN=2*IWW+1
   
SEND_REAL(NLEN) = -999.0_EB

!WRITE(SCARC_LU,*) 'SEND_REAL:'
!WRITE(SCARC_LU,'(10f12.6)') (SEND_REAL(LL),LL=1,10)

END SUBROUTINE SCARC_PACK_CVECTOR_REAL
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Pack send buffer for exchange of internal vector in compact storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PACK_CVECTOR_REAL2 (SEND_REAL, WALL, NTYPE, NLEN, NW, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(OUT) :: SEND_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER, INTENT(IN)  :: NTYPE, NW, NM, NL
INTEGER, INTENT(OUT) :: NLEN
INTEGER ::  IW, LL, IC
REAL(EB), POINTER, DIMENSION(:) :: CVEC

CVEC   => POINT_TO_CVECTOR (NTYPE, NM, NL)

SEND_REAL=0.0_EB
LL  = 1
PACK_SEND2: DO IW=1,NW

   IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND2
   SEND_REAL(LL)   = REAL(IW,EB)
   LL = LL+1

   IC = WALL(IW)%ICN(1)
   SEND_REAL(LL) = CVEC(IC)
   LL = LL+1

   IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
      IC = WALL(IW)%ICN2(1)
      SEND_REAL(LL) = CVEC(IC)
      LL = LL+1
   ENDIF

ENDDO PACK_SEND2
NLEN=LL

SEND_REAL(NLEN) = -999.0_EB

END SUBROUTINE SCARC_PACK_CVECTOR_REAL2
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Unpack receive buffer for internal update
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UNPACK_CVECTOR_REAL (RECV_REAL, WALL, NTYPE, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(IN) :: RECV_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN) :: NTYPE, NM, NL
INTEGER  :: IW, LL, IC, ICPL
REAL(EB), POINTER, DIMENSION(:) :: CVECTOR
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC

SC => SCARC(NM)%COMPACT(NL)

CVECTOR => POINT_TO_CVECTOR (NTYPE, NM, NL)

!WRITE(SCARC_LU,*) 'RECV_REAL:'
!WRITE(SCARC_LU,'(10f12.6)') (RECV_REAL(LL),LL=1,10)
LL = 0
UNPACK_RECV: DO

   IW = NINT(RECV_REAL(LL+1))
   IF (IW==-999) EXIT UNPACK_RECV
   DO ICPL = 1, WALL(IW)%NCPL
      IC = SC%WALL(IW)%ICE(ICPL)
      CVECTOR(IC) = RECV_REAL(LL+2)
!WRITE(SCARC_LU,'(a,i4,a,f12.6,3i3)') 'UNPACK CVECTOR(',IC,')=',CVECTOR(IC), IW, WALL(IW)%NCPL
      LL = LL+2
   ENDDO

ENDDO UNPACK_RECV

END SUBROUTINE SCARC_UNPACK_CVECTOR_REAL


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Unpack receive buffer for internal update
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UNPACK_CVECTOR_REAL2 (RECV_REAL, WALL, NTYPE, NM, NOM, NL)
REAL (EB), DIMENSION (:)  , INTENT(IN) :: RECV_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN) :: NTYPE, NM, NOM, NL
INTEGER  :: IW, LL, ICG, ICE
REAL(EB), POINTER, DIMENSION(:) :: OVEC, VEC

VEC  => POINT_TO_CVECTOR (NTYPE, NOM, NL)
OVEC => POINT_TO_NEIGHBORING_CVECTOR_REAL (NTYPE, NOM, NM, NL)

LL = 1
UNPACK_RECV2: DO

   IW = NINT(RECV_REAL(LL))
   IF (IW==-999) EXIT UNPACK_RECV2
   LL = LL + 1

   ICG = WALL(IW)%ICG(1)
   ICE = WALL(IW)%ICE(1)

   OVEC(ICG) = RECV_REAL(LL)
   VEC(ICE)  = RECV_REAL(LL)

   LL = LL + 1


   IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN

      ICG = WALL(IW)%ICG2(1)
      ICE = WALL(IW)%ICE2(1)

      OVEC(ICG) = RECV_REAL(LL)
      VEC(ICE)  = RECV_REAL(LL)

      LL = LL + 1


   ENDIF
   
ENDDO UNPACK_RECV2


END SUBROUTINE SCARC_UNPACK_CVECTOR_REAL2


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Pack send buffer for exchange of internal vector in compact storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PACK_CVECTOR_INT (SEND_REAL, WALL, NTYPE, NLEN, NW, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(OUT) :: SEND_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN)  :: NTYPE, NW, NM, NL
INTEGER  , INTENT(OUT) :: NLEN
INTEGER  , POINTER, DIMENSION(:) :: CVECTOR
INTEGER ::  IW, IWW, LL, IC, NCPL, ICPL
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC

SC => SCARC(NM)%COMPACT(NL)
CVECTOR => POINT_TO_CVECTOR_INT (NTYPE, NM, NL)

LL  = 0
IWW = 0
PACK_SEND: DO IW=1,NW
   IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND
   NCPL = WALL(IW)%NCPL
   DO ICPL = 1, NCPL
      IC = WALL(IW)%ICN(ICPL)
      IWW = IWW + 1
      SEND_REAL(LL+1) = REAL(IW,EB)
      SEND_REAL(LL+2) = REAL(CVECTOR(IC),EB)
      LL = LL+2
   ENDDO
ENDDO PACK_SEND
NLEN=2*IWW+1

SEND_REAL(NLEN) = -999.0_EB

END SUBROUTINE SCARC_PACK_CVECTOR_INT
 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Pack send buffer for exchange of internal vector in compact storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PACK_CVECTOR_INT2 (SEND_REAL, WALL, NTYPE, NLEN, NW, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(OUT) :: SEND_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN)  :: NTYPE, NW, NM, NL
INTEGER  , INTENT(OUT) :: NLEN
INTEGER  , POINTER, DIMENSION(:) :: CVECTOR
INTEGER ::  IW, IWW, LL, IC, NCPL, ICPL
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC

SC => SCARC(NM)%COMPACT(NL)
CVECTOR => POINT_TO_CVECTOR_INT (NTYPE, NM, NL)

LL  = 0
IWW = 0
PACK_SEND: DO IW=1,NW
   IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND
   NCPL = WALL(IW)%NCPL
   DO ICPL = 1, NCPL
      IC = WALL(IW)%ICN(ICPL)
      IWW = IWW + 1
      SEND_REAL(LL+1) = REAL(IW,EB)
      SEND_REAL(LL+2) = REAL(CVECTOR(IC),EB)
      LL = LL+2
   ENDDO
   IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
      DO ICPL = 1, NCPL
         IC = WALL(IW)%ICN2(ICPL)
         IWW = IWW + 1
         SEND_REAL(LL+1) = REAL(IW,EB)
         SEND_REAL(LL+2) = REAL(CVECTOR(IC),EB)
         LL = LL+2
      ENDDO
   ENDIF
ENDDO PACK_SEND
NLEN=2*IWW+1

SEND_REAL(NLEN) = -999.0_EB

END SUBROUTINE SCARC_PACK_CVECTOR_INT2
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Unpack receive buffer for internal update
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UNPACK_CVECTOR_INT (RECV_REAL, WALL, NTYPE, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(IN) :: RECV_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN) :: NTYPE, NM, NL
REAL (EB):: ZSUM
INTEGER  :: IW, LL, IC, NCPL, ICPL
INTEGER,  POINTER, DIMENSION(:) :: CVECTOR
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC

SC => SCARC(NM)%COMPACT(NL)

CVECTOR => POINT_TO_CVECTOR_INT (NTYPE, NM, NL)

LL = 0
UNPACK_RECV: DO

   IW = NINT(RECV_REAL(LL+1))
   IF (IW==-999) EXIT UNPACK_RECV
   ZSUM=0.0_EB
   NCPL = WALL(IW)%NCPL
   DO ICPL = 1, NCPL
      IC = WALL(IW)%ICN(ICPL)
      ZSUM=ZSUM+RECV_REAL(LL+2)
      LL = LL+2
   ENDDO

   IC = SC%WALL(IW)%ICG(1)
   CVECTOR(IC) = NINT(ZSUM/REAL(WALL(IW)%NCPL,EB))

ENDDO UNPACK_RECV

END SUBROUTINE SCARC_UNPACK_CVECTOR_INT

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Unpack receive buffer for internal update
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UNPACK_CVECTOR_INT2 (RECV_REAL, WALL, NTYPE, NM, NOM, NL)
REAL (EB), DIMENSION (:)  , INTENT(IN) :: RECV_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN) :: NTYPE, NM, NOM, NL
REAL (EB):: ZSUM1, ZSUM2
INTEGER  :: IW, LL, IC1, IC2, NCPL, ICPL
INTEGER,  POINTER, DIMENSION(:) :: OVEC, VEC
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC

SC => SCARC(NOM)%COMPACT(NL)

VEC  => POINT_TO_CVECTOR_INT (NTYPE, NOM, NL)
OVEC => POINT_TO_NEIGHBORING_CVECTOR_INT (NTYPE, NOM, NM, NL)

LL = 0
UNPACK_RECV: DO

   IW = NINT(RECV_REAL(LL+1))
   IF (IW==-999) EXIT UNPACK_RECV

   ZSUM1=0.0_EB
   NCPL = WALL(IW)%NCPL
   DO ICPL = 1, NCPL
      IC1 = WALL(IW)%ICN(ICPL)
      ZSUM1=ZSUM1+RECV_REAL(LL+2)
      LL = LL+2
   ENDDO

   IC1 = SC%WALL(IW)%ICG(1)
   OVEC(IC1) = NINT(ZSUM1/REAL(WALL(IW)%NCPL,EB))

   IC1 = SC%WALL(IW)%ICE(1)
   VEC(IC1) = NINT(ZSUM1/REAL(WALL(IW)%NCPL,EB))

   IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
      ZSUM2=0.0_EB
      DO ICPL = 1, NCPL
         IC2 = WALL(IW)%ICN2(ICPL)
         ZSUM2=ZSUM2+RECV_REAL(LL+2)
         LL = LL+2
      ENDDO

      IC2 = SC%WALL(IW)%ICG2(1)
      OVEC(IC2) = NINT(ZSUM2/REAL(WALL(IW)%NCPL,EB))

      IC2 = SC%WALL(IW)%ICE2(1)
      VEC(IC2) = NINT(ZSUM2/REAL(WALL(IW)%NCPL,EB))

   ENDIF

ENDDO UNPACK_RECV

END SUBROUTINE SCARC_UNPACK_CVECTOR_INT2


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Pack send buffer for exchange of matrix subdiagonals (for both system types)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PACK_BMATRIX (SEND_REAL, WALL, NTYPE, NLEN, NW, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(OUT) :: SEND_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN)  :: NTYPE, NW, NM, NL
INTEGER  , INTENT(OUT) :: NLEN
INTEGER ::  IW, IWW, LL, II, JJ, KK, IOR0
TYPE (SCARC_BANDED_TYPE), POINTER:: SB

SB => SCARC(NM)%BANDED(NL)

LL = 0
IWW = 0
SELECT CASE (NTYPE)

   !!! -------------------------------------------------------------------------------------------
   !!! System matrix
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_SUBDIAG)

      PACK_SEND_SYSTEM: DO IW=1,NW
         IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND_SYSTEM
         IOR0 = ABS(WALL(IW)%IOR)
         DO KK=WALL(IW)%IZN1,WALL(IW)%IZN2
            DO JJ=WALL(IW)%IYN1,WALL(IW)%IYN2
               DO II=WALL(IW)%IXN1,WALL(IW)%IXN2
                  IWW = IWW + 1
                  SEND_REAL(LL+1) = REAL(IW,EB)
                  SEND_REAL(LL+2) = SB%DI2(IOR0)
                  LL = LL+2
               ENDDO
            ENDDO
         ENDDO
      ENDDO PACK_SEND_SYSTEM

   CASE DEFAULT
   
      WRITE(*,*) 'NTYPE=',NTYPE,' NOT ALLOWED FOR SCARC_PACK_BMATRIX'
      STOP

END SELECT

NLEN=2*IWW+1
SEND_REAL(NLEN) = -999.0_EB
      
END SUBROUTINE SCARC_PACK_BMATRIX
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Unpack receive buffer for matrix-vector multiplication for compact storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UNPACK_BMATRIX (RECV_REAL, WALL, NTYPE, NM, NL)
REAL (EB), DIMENSION (:)  , INTENT(IN)  :: RECV_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN) :: NTYPE, NM, NL
REAL (EB):: ZSUM
INTEGER IW, LL, ISUM, I, J, K, II, JJ, KK, IC, ICPL
TYPE (SCARC_BANDED_TYPE), POINTER:: SB

SB => SCARC(NM)%BANDED(NL)

LL = 0
SELECT CASE (NTYPE)

   !!! -------------------------------------------------------------------------------------------
   !!! System matrix
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_SUBDIAG)
      UNPACK_RECV: DO
      
         IW = NINT(RECV_REAL(LL+1))
         IF (IW==-999) EXIT UNPACK_RECV
         ZSUM=0.0_EB
         DO KK=WALL(IW)%IZN1,WALL(IW)%IZN2
            DO JJ=WALL(IW)%IYN1,WALL(IW)%IYN2
               DO II=WALL(IW)%IXN1,WALL(IW)%IXN2
                  ZSUM=ZSUM+RECV_REAL(LL+2)
                  LL = LL+2
               ENDDO
            ENDDO
         ENDDO
      
         ISUM = (WALL(IW)%IXN2-WALL(IW)%IXN1+1) * &
                (WALL(IW)%IYN2-WALL(IW)%IYN1+1) * &
                (WALL(IW)%IZN2-WALL(IW)%IZN1+1)
      
         I=WALL(IW)%IXW
         J=WALL(IW)%IYW
         K=WALL(IW)%IZW
      
         IC = (K-1)*SB%NX*SB%NY + (J-1)*SB%NX + I
         DO ICPL = 2, SB%NCPL
            IF (IW == -SB%A(IC,ICPL)) THEN
               SB%A(IC,ICPL) = ZSUM/REAL(ISUM,EB)
               SB%WALL(IW)%ICW = IC
            ENDIF
         ENDDO
      
      ENDDO UNPACK_RECV

   CASE DEFAULT

      WRITE(*,*) 'NTYPE =',NTYPE,' NOT ALLOWED FOR SCARC_UNPACK_BMATRIX'
      STOP

END SELECT
      
END SUBROUTINE SCARC_UNPACK_BMATRIX


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Pack send buffer for exchange of matrix subdiagonals (for both system types)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_PACK_CMATRIX (SEND_REAL, WALL, NTYPE, NLEN, NW, NM, NOM, NL)
REAL (EB), DIMENSION (:)  , INTENT(OUT) :: SEND_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN)  :: NTYPE, NW, NM, NOM, NL
INTEGER  , INTENT(OUT) :: NLEN
INTEGER ::  IC, JC, ICOL, IW, IWW, LL, IOR0, NCPL, ICPL, IW0, NCOL
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC

SC  => SCARC(NM)%COMPACT(NL)

SELECT CASE (NTYPE)

   !!! -------------------------------------------------------------------------------------------
   !!! subdiagonal entries of System matrix (from adjacent cells)
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_SUBDIAG)

      LL = 1
      IWW = 0
  
      PACK_SEND_SUBDIAG: DO IW=1,NW

         IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND_SUBDIAG
         IOR0 = ABS(WALL(IW)%IOR)
         NCPL = WALL(IW)%NCPL
         SEND_REAL(LL) = REAL(IW,EB)
         LL = LL + 1
         DO ICPL = 1, NCPL
            IC = WALL(IW)%ICN(ICPL)
            SEND_REAL(LL) = SC%DI2(IOR0)
            LL = LL+1
         ENDDO
      ENDDO PACK_SEND_SUBDIAG

      NLEN=LL


   !!! -------------------------------------------------------------------------------------------
   !!! exchange sizes of matrix stencils in overlapping parts
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_STENCIL)

      LL = 1
      SEND_REAL = 0.0_EB

      !!! Pack first cell layer
      PACK_SEND_STENCIL: DO IW=1,NW
         IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND_STENCIL
   
         NCPL = WALL(IW)%NCPL

         DO ICPL = 1, NCPL
            IC = WALL(IW)%ICN(ICPL)

            SEND_REAL(LL)   = REAL(IW,EB)
            NCOL = 0
            DO ICOL = SC%A_ROW(IC), SC%A_ROW(IC+1)-1
               JC = SC%A_COL(ICOL)
               IF (JC > SC%NC) THEN
                  IW0 = SC%WALL_PTR(JC)
                  IF (SC%WALL(IW0)%NOM == NOM) NCOL = NCOL + 1
               ELSE
                  NCOL = NCOL + 1
               ENDIF
            ENDDO
            SEND_REAL(LL+1) = REAL(NCOL)

            LL = LL + 2
         ENDDO 

         !!! Pack second cell layer if requested
         IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
   
            DO ICPL = 1, NCPL
               IC = WALL(IW)%ICN2(ICPL)
   
               SEND_REAL(LL) = REAL(IW,EB)
               NCOL = 0
               DO ICOL = SC%A_ROW(IC), SC%A_ROW(IC+1)-1
                  JC = SC%A_COL(ICOL)
                  IF (JC > SC%NC) THEN
                     IW0 = SC%WALL_PTR(JC)
                     IF (SC%WALL(IW0)%NOM == NOM) NCOL = NCOL + 1
                  ELSE
                     NCOL = NCOL + 1
                  ENDIF
               ENDDO
               SEND_REAL(LL+1) = REAL(NCOL)
   
               LL = LL + 2
            ENDDO
         ENDIF
      ENDDO PACK_SEND_STENCIL

      SEND_REAL(LL) = -999.0_EB
      LL = LL + 1
      NLEN=LL-1

   !!! -------------------------------------------------------------------------------------------
   !!! subdiagonal entries of System matrix (from adjacent cells)
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_SYSTEM)

      LL = 1
      SEND_REAL = 0.0_EB

      !!! Pack first cell layer
      PACK_SEND_SYSTEM: DO IW=1,NW
         IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND_SYSTEM
   
         NCPL = WALL(IW)%NCPL

         DO ICPL = 1, NCPL
            IC = WALL(IW)%ICN(ICPL)

            SEND_REAL(LL)   = REAL(IW,EB)
            LL = LL + 1

            MATRIX_COLUMN_LOOP: DO ICOL = SC%A_ROW(IC), SC%A_ROW(IC+1)-1
               JC = SC%A_COL(ICOL)
               IF (JC > SC%NC) THEN
                  IW0 = SC%WALL_PTR(JC)
                  IF (SC%WALL(IW0)%NOM /= NOM) CYCLE MATRIX_COLUMN_LOOP
                  SEND_REAL(LL) = - REAL(SC%WALL_PTR(JC),EB)
               ELSE
                  SEND_REAL(LL) =   REAL(JC,EB)
               ENDIF
               SEND_REAL(LL+1) = SC%A(ICOL)
               LL = LL + 2
            ENDDO MATRIX_COLUMN_LOOP

         ENDDO 

         !!! Pack second cell layer if requested
         IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
   
            DO ICPL = 1, NCPL
               IC = WALL(IW)%ICN2(ICPL)
               MATRIX_COLUMN_LOOP2: DO ICOL = SC%A_ROW(IC), SC%A_ROW(IC+1)-1
                  JC = SC%A_COL(ICOL)
                  IF (JC > SC%NC) THEN
                     IW0 = SC%WALL_PTR(JC)
                     IF (SC%WALL(IW0)%NOM /= NOM) CYCLE MATRIX_COLUMN_LOOP2
                     SEND_REAL(LL) = - REAL(SC%WALL_PTR(JC),EB)
                  ELSE
                     SEND_REAL(LL) =   REAL(JC,EB)
                  ENDIF
                  SEND_REAL(LL+1) = SC%A(ICOL)
                  LL = LL + 2
               ENDDO MATRIX_COLUMN_LOOP2
   
            ENDDO 
         ENDIF
      ENDDO PACK_SEND_SYSTEM

      SEND_REAL(LL) = -999.0_EB
      NLEN=LL


   !!! -------------------------------------------------------------------------------------------
   !!! Prolongation matrix
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_PROLONGATION)

      LL = 1

      PACK_SEND_PROL: DO IW=1,NW
         IF (WALL(IW)%NOM/=NM) CYCLE PACK_SEND_PROL
         NCPL = WALL(IW)%NCPL

         SEND_REAL(LL)   = REAL(IW,EB)
         LL = LL + 1
         PROL_FIRST_LAYER_LOOP: DO IC=WALL(IW)%ICN(1),WALL(IW)%ICN(NCPL)

            SEND_REAL(LL)   = REAL(SC%CELLTYPE(IC),EB)
            SEND_REAL(LL+1) = REAL(SC%P_ROW(IC+1)-SC%P_ROW(IC),EB)

            LL = LL + 2

            DO ICOL = SC%P_ROW(IC), SC%P_ROW(IC+1)-1
               JC = SC%P_COL(ICOL)
               IF (JC >= SC%NC) THEN
                  SEND_REAL(LL) = - REAL(JC,EB)
               ELSE
                  SEND_REAL(LL) =   REAL(JC,EB)
               ENDIF
               SEND_REAL(LL+1) = SC%P(ICOL)
               LL = LL + 2
            ENDDO 

         ENDDO PROL_FIRST_LAYER_LOOP

         IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
   
            PROL_SECOND_LAYER_LOOP: DO IC=WALL(IW)%ICN2(1),WALL(IW)%ICN2(NCPL)
   
               SEND_REAL(LL)   = REAL(SC%CELLTYPE(IC),EB)
               SEND_REAL(LL+1) = REAL(SC%P_ROW(IC+1)-SC%P_ROW(IC),EB)
   
               LL = LL + 2
   
               DO ICOL = SC%P_ROW(IC), SC%P_ROW(IC+1)-1
                  JC = SC%P_COL(ICOL)
                  IF (JC >= SC%NC) THEN
                     SEND_REAL(LL) = - REAL(JC,EB)
                  ELSE
                     SEND_REAL(LL) =   REAL(JC,EB)
                  ENDIF
                  SEND_REAL(LL+1) = SC%P(ICOL)
                  LL = LL + 2
               ENDDO 
   
            ENDDO PROL_SECOND_LAYER_LOOP

         ENDIF

      ENDDO PACK_SEND_PROL
      NLEN=LL

END SELECT
SEND_REAL(NLEN) = -999.0_EB

END SUBROUTINE SCARC_PACK_CMATRIX
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Unpack receive buffer for matrix-vector multiplication for compact storage technique
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_UNPACK_CMATRIX (RECV_REAL, WALL, NTYPE, NM, NOM, NL)
REAL (EB), DIMENSION (:)  , INTENT(IN)    :: RECV_REAL
TYPE (SCARC_WALL_TYPE), DIMENSION (:), INTENT(IN)  :: WALL
INTEGER  , INTENT(IN)    :: NTYPE, NM, NOM, NL
REAL (EB):: ZSUM
INTEGER IW, LL, IC, JC, JC0, IROW, ICOL, NCOL, NROW, NCPL, ICELLTYPE, ICE, ICG, ICN, ICC
TYPE (SCARC_COMPACT_TYPE), POINTER:: SC
TYPE (OSCARC_COMPACT_TYPE), POINTER:: OSC

SC => SCARC(NM)%COMPACT(NL)

SELECT CASE (NTYPE)

   !!! -------------------------------------------------------------------------------------------
   !!! Subdiagonal matrix entries along adjacent cells
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_SUBDIAG)

      LL = 0
      UNPACK_RECV_SUBDIAG: DO
      
         IW = NINT(RECV_REAL(LL+1))
         IF (IW==-999) EXIT UNPACK_RECV_SUBDIAG
         ZSUM=0.0_EB
         NCPL = WALL(IW)%NCPL
         LL = LL + 1
         DO IC=WALL(IW)%ICN(1),WALL(IW)%ICN(NCPL)
            ZSUM=ZSUM+RECV_REAL(LL+1)
            LL = LL+1
         ENDDO
      
         IC=WALL(IW)%ICW
      
         IROW = SC%A_ROW(IC)
         DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
            IF (IW == -SC%A_COL(ICOL)) THEN
               SC%A(ICOL)     = ZSUM/REAL(WALL(IW)%NCPL,EB)
               SC%A_COL(ICOL) = SC%WALL(IW)%ICE(1)
            ENDIF
         ENDDO
      
         IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN

            IW = NINT(RECV_REAL(LL+1))
            IF (IW==-999) EXIT UNPACK_RECV_SUBDIAG
            ZSUM=0.0_EB
            NCPL = WALL(IW)%NCPL
            LL = LL + 1
            DO IC=WALL(IW)%ICN2(1),WALL(IW)%ICN2(NCPL)
               ZSUM=ZSUM+RECV_REAL(LL+1)
               LL = LL+1
            ENDDO
         
            IC=WALL(IW)%ICW
         
            IROW = SC%A_ROW(IC)
            DO ICOL = SC%A_ROW(IC)+1, SC%A_ROW(IC+1)-1
               IF (IW == -SC%A_COL(ICOL)) THEN
                  SC%A(ICOL)     = ZSUM/REAL(WALL(IW)%NCPL,EB)
                  SC%A_COL(ICOL) = SC%WALL(IW)%ICE(1)
               ENDIF
            ENDDO
         
         ENDIF

      ENDDO UNPACK_RECV_SUBDIAG
   
   
   !!! -------------------------------------------------------------------------------------------
   !!! Stencil size of system  matrix
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_STENCIL)

      SC => SCARC(NM)%COMPACT(NL)
      OSC => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
      LL = 1

      !!! Unpack first cell layer
      UNPACK_RECV_STENCIL: DO
   
         IW = NINT(RECV_REAL(LL))
         IF (IW==-888.OR.IW==-999) EXIT UNPACK_RECV_STENCIL
   
         !!! ------------------------  First layer  ---------------------------------------------
         ICG = SC%WALL(IW)%ICG(1)
         OSC%A_SIZE(ICG) = NINT(RECV_REAL(LL+1))
         LL = LL + 2

         IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
             IW = NINT(RECV_REAL(LL))
             IF (IW==-999) EXIT UNPACK_RECV_STENCIL
   
             !!! Unpack second cell layer if requested
             ICG = SC%WALL(IW)%ICG2(1)
             OSC%A_SIZE(ICG) = NINT(RECV_REAL(LL+1))
             LL = LL + 2
          ENDIF

       ENDDO UNPACK_RECV_STENCIL


   !!! -------------------------------------------------------------------------------------------
   !!! System matrix
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_SYSTEM)

      SC  => SCARC(NM)%COMPACT(NL)
      OSC => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
      LL = 1

      !!! Unpack first cell layer
      UNPACK_RECV_SYSTEM: DO
   
         IW = NINT(RECV_REAL(LL))
         IF (IW==-888.OR.IW==-999) EXIT UNPACK_RECV_SYSTEM
         LL = LL + 1
   
         !!! ------------------------  First layer  ---------------------------------------------
         ICE = SC%WALL(IW)%ICE(1)
         DO ICOL = SC%A_ROW(ICE), SC%A_ROW(ICE+1)-1
            JC0 = NINT(RECV_REAL(LL))
            IF (JC0 > 0) THEN
               JC = - JC0
            ELSE IF (JC0 < 0) THEN
               JC = SC%WALL(IW)%ICW
            ENDIF
            SC%A_COL(ICOL)= JC
            SC%A(ICOL)    = RECV_REAL(LL+1)
            LL = LL + 2
         ENDDO 


          !!! Unpack second cell layer if requested
         IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN
            ICE = SC%WALL(IW)%ICE2(1)
            DO ICOL = SC%A_ROW(ICE), SC%A_ROW(ICE+1)-1
               SC%A_COL(ICOL)= - NINT(RECV_REAL(LL))
               SC%A(ICOL)    = RECV_REAL(LL+1)
               LL = LL + 2
            ENDDO 
          ENDIF
       ENDDO UNPACK_RECV_SYSTEM


   !!! -------------------------------------------------------------------------------------------
   !!! Prolongation matrix
   !!! -------------------------------------------------------------------------------------------
   CASE (NSCARC_MATRIX_PROLONGATION)

      SC  => SCARC(NM)%COMPACT(NL)
      OSC => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)
      LL = 1

      !!! ------------------------  First layer  ---------------------------------------------
      NROW=1
      ICC = 1
      UNPACK_RECV_PROL: DO
   
         IW = NINT(RECV_REAL(LL))
         LL = LL + 1
         IF (IW==-888.OR.IW==-999) EXIT UNPACK_RECV_PROL
   
         ICG = SC%WALL(IW)%ICG(1)
         ICE = SC%WALL(IW)%ICE(1)
         ICN = SC%WALL(IW)%ICN(1)
         ICELLTYPE = NINT(RECV_REAL(LL))
         NCOL      = NINT(RECV_REAL(LL+1))
         
         OSC%CELLTYPE(ICG) = ICELLTYPE
         OSC%P_ROW(ICG) = NROW

         LL = LL + 2

         DO ICOL = NROW, NROW+NCOL-1
            OSC%P_COL(ICOL)= NINT(RECV_REAL(LL))
            OSC%P(ICOL)    = RECV_REAL(LL+1)
            LL = LL + 2
         ENDDO 
         NROW = NROW + NCOL
         OSC%P_ROW(ICG+1) = NROW


      !!! ------------------------  Second layer ? -------------------------------------------
         IF (NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) THEN

   
            ICG = SC%WALL(IW)%ICG2(1)
            ICE = SC%WALL(IW)%ICE(1)
            ICN = SC%WALL(IW)%ICN(1)

            ICELLTYPE = NINT(RECV_REAL(LL))
            NCOL      = NINT(RECV_REAL(LL+1))
         
            OSC%CELLTYPE(ICG) = ICELLTYPE
            OSC%P_ROW(ICG) = NROW

            LL = LL + 2

            DO ICOL = NROW, NROW+NCOL-1
               OSC%P_COL(ICOL)= NINT(RECV_REAL(LL))
               OSC%P(ICOL)    = RECV_REAL(LL+1)
               LL = LL + 2
            ENDDO 
            NROW = NROW + NCOL
            OSC%P_ROW(ICG+1) = NROW

         ENDIF
      ENDDO UNPACK_RECV_PROL

END SELECT
      
END SUBROUTINE SCARC_UNPACK_CMATRIX


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Check if difference of two values is less than a given tolerance
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
LOGICAL FUNCTION MATCH (VAL1, VAL2)
REAL (EB), INTENT(IN) :: VAL1, VAL2
REAL (EB) :: TOL
TOL = 1.0E-10_EB
MATCH = .FALSE.
IF (Abs(VAL1-VAL2) <= TOL) MATCH = .TRUE.
RETURN
END FUNCTION MATCH
 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Debug requested quantity
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_DEBUG_QUANTITY(NTYPE, NL, CROUTINE, CNAME)
INTEGER, INTENT(IN) :: NTYPE, NL
INTEGER :: NM, NOM, IP, IC, IW, I, J, K
CHARACTER (*), INTENT(IN) :: CROUTINE, CNAME
CHARACTER (20) :: LINE
TYPE (OSCARC_TYPE) , POINTER :: OS
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC, SC1, SC2, SC3, SC4
TYPE (OSCARC_COMPACT_TYPE), POINTER :: OSC, OSC1, OSC2, OSC12, OSC13, OSC21, OSC24, OSC31, OSC34, OSC42, OSC43

IF (TYPE_DEBUG < NSCARC_DEBUG_LESS) RETURN

SELECT CASE (NTYPE)

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug system matrix A (corresponding to system type)
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_MATRIX)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
            SB  => SCARC(NM)%BANDED(NL)
            WRITE(SCARC_LU,*) '----------------- A(.,.):'
            WRITE(SCARC_LU,*) 'NX=',SB%NX
            WRITE(SCARC_LU,*) 'NY=',SB%NY
            WRITE(SCARC_LU,*) 'NZ=',SB%NZ
            WRITE(SCARC_LU,*) 'NA=',SB%NA
            WRITE(SCARC_LU,*) 'NC=',SB%NC
            IF (TYPE_DIMENSION == NSCARC_DIMENSION_TWO) THEN
               DO IC = 1, SB%NC
                  WRITE(SCARC_LU,'(i7,5f13.2)') IC,SB%A(IC,ILZ),SB%A(IC,ILX),SB%A(IC,ID),SB%A(IC,IUX),SB%A(IC,IUZ)
                  IF (MOD(IC,SB%NX)==0) WRITE(SCARC_LU,*) '----------------------------------------------'
               ENDDO
            ELSE
               DO IC = 1, SB%NC
                  WRITE(SCARC_LU,'(i7,7f13.2)') IC,SB%A(IC,ILZ),SB%A(IC,ILY),SB%A(IC,ILX),SB%A(IC,ID),&
                                                SB%A(IC,IUX),SB%A(IC,IUY),SB%A(IC,IUZ)
                  IF (MOD(IC,SB%NX)==0) WRITE(SCARC_LU,*) '----------------------------------------------'
               ENDDO
            ENDIF
         ELSE
            SC => SCARC(NM)%COMPACT(NL)
            WRITE(SCARC_LU,*) 'NA =',SC%NA
            WRITE(SCARC_LU,*) 'NC =',SC%NC
            WRITE(SCARC_LU,*) 'NCE=',SC%NCE
            WRITE(SCARC_LU,*) '---------------------- A_ROW:', SC%NCE
            WRITE(SCARC_LU,'(4i9)') (SC%A_ROW(IC), IC=1,SC%NCE+1)
            WRITE(SCARC_LU,*) '---------------------- A_COL:'
            DO IC = 1, SC%NCE
               WRITE(SCARC_LU,'(i5,a,20i9)') IC,':',(SC%A_COL(IP),IP=SC%A_ROW(IC),SC%A_ROW(IC+1)-1)
            ENDDO
            WRITE(SCARC_LU,*) '---------------------- A:'
            DO IC = 1, SC%NCE
               WRITE(SCARC_LU,'(i5,a,20f9.2)') IC,':',(SC%A(IP),IP=SC%A_ROW(IC),SC%A_ROW(IC+1)-1)
            ENDDO
            WRITE(SCARC_LU,*) 'SIZE(A) =',SIZE(SC%A)
            WRITE(SCARC_LU,*) 'SIZE(A_COL) =',SIZE(SC%A_COL)
            WRITE(SCARC_LU,*) 'SIZE(A_ROW) =',SIZE(SC%A_ROW)
         ENDIF
      ENDDO

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug extended system matrix A (corresponding to system type)
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_MATRIXE)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
            SB  => SCARC(NM)%BANDED(NL)
            WRITE(SCARC_LU,*) '----------------- A(.,.):'
            DO IC = 1, SB%NC
               WRITE(SCARC_LU,'(5f12.3)') SB%A(IC,ILZ),SB%A(IC,ILX),SB%A(IC,ID),SB%A(IC,IUX),SB%A(IC,IUZ)
               IF (MOD(IC,SB%NX)==0) WRITE(SCARC_LU,*) '----------------------------------------------'
            ENDDO
         ELSE
            SC => SCARC(NM)%COMPACT(NL)
            WRITE(SCARC_LU,*) '---------------------- A_ROW:', SC%NC
            WRITE(SCARC_LU,'(4i9)') (SC%A_ROW(IC), IC=1,SC%NC+1)
            WRITE(SCARC_LU,*) '---------------------- A_COL:'
            DO IC = 1, SC%NC
               WRITE(SCARC_LU,'(i5,a,20i9)') IC,':',(SC%A_COL(IP),IP=SC%A_ROW(IC),SC%A_ROW(IC+1)-1)
            ENDDO
            WRITE(SCARC_LU,*) '---------------------- A:'
            DO IC = 1, SC%NC
               WRITE(SCARC_LU,'(i5,a,20f9.2)') IC,':',(SC%A(IP),IP=SC%A_ROW(IC),SC%A_ROW(IC+1)-1)
            ENDDO
            WRITE(SCARC_LU,*) 'SIZE(A) =',SIZE(SC%A)
            WRITE(SCARC_LU,*) 'SIZE(A_COL) =',SIZE(SC%A_COL)
            WRITE(SCARC_LU,*) 'SIZE(A_ROW) =',SIZE(SC%A_ROW)
         ENDIF
      ENDDO

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug prolongation matrix P (only for compact system)
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_PROLONGATION)

      DO NM = NMESHES_MIN, NMESHES_MAX
         SC => SCARC(NM)%COMPACT(NL)
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         WRITE(SCARC_LU,*) '============= P_ROW:', NM
         WRITE(SCARC_LU,'(4i9)') (SC%P_ROW(IC), IC=1, SC%NCE+1)
         WRITE(SCARC_LU,*) '============= P_COL:', NM
         DO IC=1,SC%NCE
            WRITE(SCARC_LU,'(i5,a,10i9)') IC,':',(SC%P_COL(IP), IP=SC%P_ROW(IC),SC%P_ROW(IC+1)-1)
         ENDDO
         WRITE(SCARC_LU,*) '============= P:', NM
         DO IC=1,SC%NCE
            WRITE(SCARC_LU,'(i5,a,10f9.2)') IC,':',(SC%P(IP), IP=SC%P_ROW(IC),SC%P_ROW(IC+1)-1)
         ENDDO
         DO NOM = 1, NMESHES
            IF (NOM == NM) CYCLE 
            OS  => SCARC(NM)%OSCARC(NOM)      
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE 
            OSC  => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)      
            WRITE(SCARC_LU,'(a,i3,a,i3,a,i3)') '============= SCARC(',NM,')%OSCARC(',NOM,')%P_ROW:', OSC%NG
            WRITE(SCARC_LU,'(4i9)') (OSC%P_ROW(IC), IC=1, OSC%NG+1)
            WRITE(SCARC_LU,'(a,i3,a,i3,a,i3)') '============= SCARC(',NM,')%OSCARC(',NOM,')%P_COL:', OSC%NG
            DO IC=1,OSC%NG
               WRITE(SCARC_LU,'(i5,a,10i9)') IC,':',(OSC%P_COL(IP), IP=OSC%P_ROW(IC),OSC%P_ROW(IC+1)-1)
            ENDDO
            WRITE(SCARC_LU,'(a,i3,a,i3,a,i3)') '============= SCARC(',NM,')%OSCARC(',NOM,')%P:'
            DO IC=1,OSC%NG
               WRITE(SCARC_LU,'(i5,a,10f9.2)') IC,':',(OSC%P(IP), IP=OSC%P_ROW(IC),OSC%P_ROW(IC+1)-1)
            ENDDO
         ENDDO
      ENDDO

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug restriction matrix R (only for compact system)
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_RESTRICTION)

      DO NM = NMESHES_MIN, NMESHES_MAX
         SC  => SCARC(NM)%COMPACT(NL)
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         WRITE(SCARC_LU,*) '============= R_ROW:', NM
         WRITE(SCARC_LU,'(4i9)') (SC%R_ROW(IC), IC=1, SC%NCCE)
         WRITE(SCARC_LU,*) '============= R_COL:', NM
         DO IC=1,SC%NCC
            WRITE(SCARC_LU,'(i5,a,10i9)') IC,':',(SC%R_COL(IP), IP=SC%R_ROW(IC),SC%R_ROW(IC+1)-1)
         ENDDO
         WRITE(SCARC_LU,*) '============= R:', NM
         DO IC=1,SC%NCC
            WRITE(SCARC_LU,'(i5,a,10f9.2)') IC,':',(SC%R(IP), IP=SC%R_ROW(IC),SC%R_ROW(IC+1)-1)
         ENDDO
         !DO NOM = 1, NMESHES
         DO NOM = 1000, NMESHES_MAX
            IF (NOM == NM) CYCLE 
            OS  => SCARC(NM)%OSCARC(NOM)      
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE 
            OSC  => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)      
            WRITE(SCARC_LU,'(a,i3,a,i3,a,i3)') '============= SCARC(',NM,')%OSCARC(',NOM,')%R_ROW:', OSC%NCC
            WRITE(SCARC_LU,'(4i9)') (OSC%R_ROW(IC), IC=1, OSC%NCC+1)
            WRITE(SCARC_LU,'(a,i3,a,i3,a,i3)') '============= SCARC(',NM,')%OSCARC(',NOM,')%R_COL:', OSC%NCC
            DO IC=1,OSC%NCC
               WRITE(SCARC_LU,'(i5,a,10i9)') IC,':',(OSC%R_COL(IP), IP=OSC%R_ROW(IC),OSC%R_ROW(IC+1)-1)
            ENDDO
            WRITE(SCARC_LU,'(a,i3,a,i3,a,i3)') '============= SCARC(',NM,')%OSCARC(',NOM,')%P:', OSC%NCC
            DO IC=1,OSC%NCC
               WRITE(SCARC_LU,'(i5,a,10f9.2)') IC,':',(OSC%R(IP), IP=OSC%R_ROW(IC),OSC%R_ROW(IC+1)-1)
            ENDDO
         ENDDO
      ENDDO

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug WALLINFO
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_WALLINFO)

!WRITE(SCARC_LU,*) ': NL=',NL, ': CNAME=',CNAME,': CROUTINE=',CROUTINE
      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN

            SB => SCARC(NM)%BANDED(NL)

            !WRITE(SCARC_LU,*) '============= WALL(.)%ICG:', NM
            !WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%ICG(1), IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%ICW:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%ICW, IW=1,SB%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IXG:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IXG, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IYG:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IYG, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IZG:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IZG, IW=1,SB%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IXW:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IXW, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IYW:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IYW, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IZW:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IZW, IW=1,SB%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IXN1:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IXN1, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IXN2:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IXN2, IW=1,SB%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IYN1:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IYN1, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IYN2:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IYN2, IW=1,SB%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IZN1:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IZN1, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IZN2:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IZN2, IW=1,SB%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IOR:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%IOR, IW=1,SB%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%NOM:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%NOM, IW=1,SB%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%NCPL:', NM
            WRITE(SCARC_LU,'(16i5)') (SB%WALL(IW)%NCPL, IW=1,SB%NW)
            WRITE(SCARC_LU,*)

         ELSE

            SC => SCARC(NM)%COMPACT(NL)

            IF (NL == 1) THEN
            WRITE(SCARC_LU,*) '============= WALL(.)%IXG:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%IXG, IW=1,SC%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IYG:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%IYG, IW=1,SC%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IZG:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%IZG, IW=1,SC%NW)
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IXW:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%IXW, IW=1,SC%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IYW:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%IYW, IW=1,SC%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%IZW:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%IZW, IW=1,SC%NW)
            ENDIF
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%IOR:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%IOR, IW=1,SC%NW)
            WRITE(SCARC_LU,*) '============= WALL(.)%NOM:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%NOM, IW=1,SC%NW)
            WRITE(SCARC_LU,*)
            IF (NL == 1) THEN
            WRITE(SCARC_LU,*) '============= WALL(.)%NCPL:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%NCPL, IW=1,SC%NW)
            ENDIF
            WRITE(SCARC_LU,*)
            WRITE(SCARC_LU,*) '============= WALL(.)%ICW:', NM
            WRITE(SCARC_LU,'(16i5)') (SC%WALL(IW)%ICW, IW=1,SC%NW)
            WRITE(SCARC_LU,*)
            IF (NL == 1) THEN
            WRITE(SCARC_LU,*) '============= WALL(.)%ICW2:', NM
            ENDIF
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',SC%WALL(IW)%ICW
            ENDDO
            WRITE(SCARC_LU,*) '============= WALL(.)%ICW2:', NM
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0.AND.NL==NLEVEL_MIN.AND.TYPE_LAYER==NSCARC_LAYER_TWO) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',SC%WALL(IW)%ICW2
            ENDDO
            IF (NL == 1) THEN
            WRITE(SCARC_LU,*) '============= WALL(.)%ICN:', NM
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',(SC%WALL(IW)%ICN(J), J=1,SC%WALL(IW)%NCPL)
            ENDDO
            WRITE(SCARC_LU,*) '============= WALL(.)%ICN2:', NM
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0.AND.NL==NLEVEL_MIN.AND.TYPE_LAYER==NSCARC_LAYER_TWO) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',(SC%WALL(IW)%ICN2(J), J=1,SC%WALL(IW)%NCPL)
            ENDDO
            ENDIF
            IF (NL == 1) THEN
            WRITE(SCARC_LU,*) '============= WALL(.)%ICE:', NM
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',(SC%WALL(IW)%ICE(J), J=1,SC%WALL(IW)%NCPL)
            ENDDO
            WRITE(SCARC_LU,*) '============= WALL(.)%ICE2:', NM
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0.AND.NL==NLEVEL_MIN.AND.TYPE_LAYER==NSCARC_LAYER_TWO) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',(SC%WALL(IW)%ICE2(J), J=1,SC%WALL(IW)%NCPL)
            ENDDO
            ENDIF
            IF (NL == 1) THEN
            WRITE(SCARC_LU,*) '============= WALL(.)%ICG:', NM
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',(SC%WALL(IW)%ICG(J), J=1,SC%WALL(IW)%NCPL)
            ENDDO
            WRITE(SCARC_LU,*) '============= WALL(.)%ICG2:', NM
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM /=0.AND.NL==NLEVEL_MIN.AND.TYPE_LAYER==NSCARC_LAYER_TWO) &
                  WRITE(SCARC_LU,'(a,i3, a,16i5)') 'IW=',IW,':',(SC%WALL(IW)%ICG2(J), J=1,SC%WALL(IW)%NCPL)
            ENDDO
            ENDIF
         ENDIF
      ENDDO


   !!!----------------------------------------------------------------------------------------------------
   !!! Debug PRESSURE_BC_INDEX
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_BCINDEX)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
            SB => SCARC(NM)%BANDED(NL)
            WRITE(SCARC_LU, '(8i4)') (SB%WALL(J)%BTYPE, J=1,SB%NW)
         ELSE
            SC => SCARC(NM)%COMPACT(NL)
            WRITE(SCARC_LU, '(8i4)') (SC%WALL(J)%BTYPE, J=1,SC%NW)
         ENDIF
      ENDDO
      
   !!!----------------------------------------------------------------------------------------------------
   !!! Debug WALL_CELL
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_ACELL)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
            SB => SCARC(NM)%BANDED(NL)
            WRITE(SCARC_LU, '(8i8)') (SB%WALL(IW)%ICW, IW=1,SB%NW)
         ELSE
            SC  => SCARC(NM)%COMPACT(NL)
            WRITE(SCARC_LU, '(8i8)') (SC%WALL(IW)%ICW, IW=1,SC%NW)
         ENDIF
      ENDDO
      
   !!!----------------------------------------------------------------------------------------------------
   !!! Debug GHOST_CELL
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_GCELL)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
            SB => SCARC(NM)%BANDED(NL)
            DO IW=1,SB%NW
               IF (SB%WALL(IW)%NOM/=0) &
                  WRITE(SCARC_LU, '(8i8)') (SB%WALL(IW)%ICG(I), I=1,SB%WALL(IW)%NCPL)
            ENDDO
         ELSE
            SC  => SCARC(NM)%COMPACT(NL)
            WRITE(SCARC_LU,*) '-------- GHOST,  NGE=',SC%NG
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM/=0) &
                  WRITE(SCARC_LU, '(8i8)') (SC%WALL(IW)%ICG(I), I=1,SC%WALL(IW)%NCPL)
            ENDDO
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM/=0.AND.NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) &
                  WRITE(SCARC_LU, '(8i8)') (SC%WALL(IW)%ICG2(I), I=1,SC%WALL(IW)%NCPL)
            ENDDO
         ENDIF
      ENDDO

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug NOM_CELL
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_NCELL)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
            SB => SCARC(NM)%BANDED(NL)
            DO IW=1,SB%NW
               IF (SB%WALL(IW)%NOM/=0) &
                  WRITE(SCARC_LU, '(8i8)') (SB%WALL(IW)%ICN(I), I=1,SB%WALL(IW)%NCPL)
            ENDDO
         ELSE
            SC  => SCARC(NM)%COMPACT(NL)
            WRITE(SCARC_LU,*) '-------- NOM, NCE= ', SC%NCE
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM/=0) &
                  WRITE(SCARC_LU, '(8i8)') (SC%WALL(IW)%ICN(I), I=1,SC%WALL(IW)%NCPL)
            ENDDO
            DO IW=1,SC%NW
               IF (SC%WALL(IW)%NOM/=0.AND.NL==NLEVEL_MIN.AND.TYPE_LAYER == NSCARC_LAYER_TWO) &
                  WRITE(SCARC_LU, '(8i8)') (SC%WALL(IW)%ICN2(I), I=1,SC%WALL(IW)%NCPL)
            ENDDO
         ENDIF
      ENDDO
      
   !!!----------------------------------------------------------------------------------------------------
   !!! Debug SUBDIVISION
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_SUBDIVISION)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         IF (TYPE_SYSTEM == NSCARC_SYSTEM_BANDED) THEN
            SB  => SCARC(NM)%BANDED(NL)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR= 1 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I, 1), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR=-1 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I,-1), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR= 2 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I, 2), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR=-2 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I,-2), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR= 3 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I, 3), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR=-3 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I,-3), I=1,3)
         ELSE
            SC  => SCARC(NM)%COMPACT(NL)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR= 1 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I, 1), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR=-1 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I,-1), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR= 2 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I, 2), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR=-2 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I,-2), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR= 3 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I, 3), I=1,3)
            WRITE(SCARC_LU,*) 'SUBDIVISION IOR=-3 '
            WRITE(SCARC_LU,'(3i4)') (SC%SUBDIVISION(I,-3), I=1,3)
         ENDIF
      ENDDO
   
   !!!----------------------------------------------------------------------------------------------------
   !!! Debug MEASURE
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_MEASURE)

      WRITE(SCARC_LU,1000) CROUTINE, CNAME, 1, NL
      IF (NMESHES == 1.OR.NL>1) THEN                !!! only temporarily
      DO NM = NMESHES_MIN, NMESHES_MAX
         SC  => SCARC(NM)%COMPACT(NL)
         IF (NL == 1) THEN
            DO K = SC%NZ, 1, -1
               WRITE(SCARC_LU, '(10f6.2)') (SC%MEASURE((K-1)*SC%NX*SC%NY+I), I=1, SC%NX)
            ENDDO
         ELSE
            WRITE(SCARC_LU, '(4f6.2)') (SC%MEASURE(IC), IC=1, SC%NC)
         ENDIF
      ENDDO
      ELSE IF (NMESHES==4) THEN
      SC1 => SCARC(1)%COMPACT(NL)
      SC2 => SCARC(2)%COMPACT(NL)
      SC3 => SCARC(3)%COMPACT(NL)
      SC4 => SCARC(4)%COMPACT(NL)
      OSC12 => SCARC(1)%OSCARC(2)%COMPACT(NL)
      OSC13 => SCARC(1)%OSCARC(3)%COMPACT(NL)
      OSC21 => SCARC(2)%OSCARC(1)%COMPACT(NL)
      OSC24 => SCARC(2)%OSCARC(4)%COMPACT(NL)
      OSC31 => SCARC(3)%OSCARC(1)%COMPACT(NL)
      OSC34 => SCARC(3)%OSCARC(4)%COMPACT(NL)
      OSC42 => SCARC(4)%OSCARC(2)%COMPACT(NL)
      OSC43 => SCARC(4)%OSCARC(3)%COMPACT(NL)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC3%MEASURE(16:20),OSC34%MEASURE(7), OSC43%MEASURE(7),SC4%MEASURE(13:16)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC3%MEASURE(11:15),OSC34%MEASURE(5), OSC43%MEASURE(5),SC4%MEASURE(9:12)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC3%MEASURE( 6:10),OSC34%MEASURE(3), OSC43%MEASURE(3),SC4%MEASURE(5:8)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC3%MEASURE( 1: 5),OSC34%MEASURE(1), OSC43%MEASURE(1),SC4%MEASURE(1: 4)
      WRITE(SCARC_LU,'(5F6.2,18X,5F6.2)') OSC31%MEASURE( 1: 9:2),OSC42%MEASURE(1:7:2)
      WRITE(SCARC_LU,*)
      WRITE(SCARC_LU,'(5F6.2,18X,5F6.2)') OSC13%MEASURE( 1: 9:2),OSC24%MEASURE(1:7:2)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC1%MEASURE(16:20),OSC12%MEASURE(7), OSC21%MEASURE(7),SC2%MEASURE(13:16)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC1%MEASURE(11:15),OSC12%MEASURE(5), OSC21%MEASURE(5),SC2%MEASURE(9:12)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC1%MEASURE( 6:10),OSC12%MEASURE(3), OSC21%MEASURE(3),SC2%MEASURE( 5:8)
      WRITE(SCARC_LU,'(6f6.2,6X,6f6.2)') SC1%MEASURE( 1: 5),OSC12%MEASURE(1), OSC21%MEASURE(1),SC2%MEASURE( 1: 4)
      ELSE IF (NMESHES==2 .AND. SCARC(1)%COMPACT(1)%NX == 5) THEN
      SC1 => SCARC(1)%COMPACT(NL)
      SC2 => SCARC(2)%COMPACT(NL)
      OSC1 => SCARC(1)%OSCARC(2)%COMPACT(NL)
      OSC2 => SCARC(2)%OSCARC(1)%COMPACT(NL)
      WRITE(SCARC_LU,'(5F6.2,a,1F6.2,6X,1F6.2,a,4F6.2)') &
                               SC1%MEASURE(16:20),'|',OSC1%MEASURE(4), OSC2%MEASURE(4),'|',SC2%MEASURE(13:16)
      WRITE(SCARC_LU,'(5F6.2,a,1F6.2,6X,1F6.2,a,4F6.2)') &
                               SC1%MEASURE(11:15),'|',OSC1%MEASURE(3), OSC2%MEASURE(3),'|',SC2%MEASURE(9:12)
      WRITE(SCARC_LU,'(5F6.2,a,1F6.2,6X,1F6.2,a,4F6.2)') &
                               SC1%MEASURE(6:10) ,'|',OSC1%MEASURE(2), OSC2%MEASURE(2),'|',SC2%MEASURE(5:8)
      WRITE(SCARC_LU,'(5F6.2,a,1F6.2,6X,1F6.2,a,4F6.2)') &
                               SC1%MEASURE(1:5)  ,'|',OSC1%MEASURE(1), OSC2%MEASURE(1),'|',SC2%MEASURE(1:4)
      ELSE IF (SCARC(1)%COMPACT(1)%NX == 8) THEN
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(57:64),SC1%MEASURE(72),SC2%MEASURE(72),SC2%MEASURE(57:64)
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(49:56),SC1%MEASURE(71),SC2%MEASURE(71),SC2%MEASURE(49:56)
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(41:48),SC1%MEASURE(70),SC2%MEASURE(70),SC2%MEASURE(41:48)
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(33:40),SC1%MEASURE(69),SC2%MEASURE(69),SC2%MEASURE(33:40)
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(25:32),SC1%MEASURE(68),SC2%MEASURE(68),SC2%MEASURE(25:32)
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(17:24),SC1%MEASURE(67),SC2%MEASURE(67),SC2%MEASURE(17:24)
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(9:16) ,SC1%MEASURE(66),SC2%MEASURE(66),SC2%MEASURE(9:16)
      WRITE(SCARC_LU,'(9F6.2,6X,9F6.2)') SC1%MEASURE(1:8)  ,SC1%MEASURE(65),SC2%MEASURE(65),SC2%MEASURE(1:8)
      ELSE IF (SCARC(1)%COMPACT(1)%NX == 9) THEN
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(64:72),SC1%MEASURE(80),SC2%MEASURE(72),SC2%MEASURE(57:64)
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(55:63),SC1%MEASURE(79),SC2%MEASURE(71),SC2%MEASURE(49:56)
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(46:54),SC1%MEASURE(78),SC2%MEASURE(70),SC2%MEASURE(41:48)
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(37:45),SC1%MEASURE(77),SC2%MEASURE(69),SC2%MEASURE(33:40)
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(28:36),SC1%MEASURE(76),SC2%MEASURE(68),SC2%MEASURE(25:32)
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(19:27),SC1%MEASURE(75),SC2%MEASURE(67),SC2%MEASURE(17:24)
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(10:18),SC1%MEASURE(74),SC2%MEASURE(66),SC2%MEASURE(9:16)
      WRITE(SCARC_LU,'(10f6.2,6X,9f6.2)') SC1%MEASURE(1:9)  ,SC1%MEASURE(73),SC2%MEASURE(65),SC2%MEASURE(1:8)
      ENDIF

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug CELLTYPE
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_CELLTYPE)

      WRITE(SCARC_LU,1000) CROUTINE, CNAME, 1, NL
      IF (NMESHES == 1.OR.NL>1) THEN                !!! only temporarily
      DO NM = NMESHES_MIN, NMESHES_MAX
         SC  => SCARC(NM)%COMPACT(NL)
         IF (NL == 1) THEN
            DO K = SC%NZ, 1, -1
               WRITE(SCARC_LU, '(10i5)') (SC%CELLTYPE((K-1)*SC%NX*SC%NY+I), I=1, SC%NX)
            ENDDO
         ELSE
            WRITE(SCARC_LU, '(4i5)') (SC%CELLTYPE(IC), IC=1, SC%NC)
         ENDIF
      ENDDO
      ELSE IF (SCARC(1)%COMPACT(1)%NX == 4) THEN
      WRITE(SCARC_LU,'(5I6,6X,5I6)') SC1%CELLTYPE(13:16),SC1%CELLTYPE(20),SC2%CELLTYPE(20),SC2%CELLTYPE(13:16)
      WRITE(SCARC_LU,'(5I6,6X,5I6)') SC1%CELLTYPE(9:12),SC1%CELLTYPE(19),SC2%CELLTYPE(19),SC2%CELLTYPE(9:12)
      WRITE(SCARC_LU,'(5I6,6X,5I6)') SC1%CELLTYPE(5:8) ,SC1%CELLTYPE(18),SC2%CELLTYPE(18),SC2%CELLTYPE(5:8)
      WRITE(SCARC_LU,'(5I6,6X,5I6)') SC1%CELLTYPE(1:4)  ,SC1%CELLTYPE(17),SC2%CELLTYPE(17),SC2%CELLTYPE(1:4)
      ELSE IF (NMESHES==4) THEN
      SC1 => SCARC(1)%COMPACT(NL)
      SC2 => SCARC(2)%COMPACT(NL)
      SC3 => SCARC(3)%COMPACT(NL)
      SC4 => SCARC(4)%COMPACT(NL)
      OSC12 => SCARC(1)%OSCARC(2)%COMPACT(NL)
      OSC13 => SCARC(1)%OSCARC(3)%COMPACT(NL)
      OSC21 => SCARC(2)%OSCARC(1)%COMPACT(NL)
      OSC24 => SCARC(2)%OSCARC(4)%COMPACT(NL)
      OSC31 => SCARC(3)%OSCARC(1)%COMPACT(NL)
      OSC34 => SCARC(3)%OSCARC(4)%COMPACT(NL)
      OSC42 => SCARC(4)%OSCARC(2)%COMPACT(NL)
      OSC43 => SCARC(4)%OSCARC(3)%COMPACT(NL)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC3%CELLTYPE(16:20),OSC34%CELLTYPE(7), OSC43%CELLTYPE(7),SC4%CELLTYPE(13:16)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC3%CELLTYPE(11:15),OSC34%CELLTYPE(5), OSC43%CELLTYPE(5),SC4%CELLTYPE(9:12)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC3%CELLTYPE( 6:10),OSC34%CELLTYPE(3), OSC43%CELLTYPE(3),SC4%CELLTYPE( 5:8)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC3%CELLTYPE( 1: 5),OSC34%CELLTYPE(1), OSC43%CELLTYPE(1),SC4%CELLTYPE( 1: 4)
      WRITE(SCARC_LU,'(5I6,18X,5I6)') OSC31%CELLTYPE( 1: 9:2),OSC42%CELLTYPE(1:7:2)
      WRITE(SCARC_LU,*)
      WRITE(SCARC_LU,'(5I6,18X,5I6)') OSC13%CELLTYPE( 1: 9:2),OSC24%CELLTYPE(1:7:2)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC1%CELLTYPE(16:20),OSC12%CELLTYPE(7), OSC21%CELLTYPE(7),SC2%CELLTYPE(13:16)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC1%CELLTYPE(11:15),OSC12%CELLTYPE(5), OSC21%CELLTYPE(5),SC2%CELLTYPE(9:12)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC1%CELLTYPE( 6:10),OSC12%CELLTYPE(3), OSC21%CELLTYPE(3),SC2%CELLTYPE(5:8)
      WRITE(SCARC_LU,'(6I6,6X,6I6)') SC1%CELLTYPE( 1: 5),OSC12%CELLTYPE(1), OSC21%CELLTYPE(1),SC2%CELLTYPE(1: 4)
      ELSE IF (NMESHES==2 .AND. SCARC(1)%COMPACT(1)%NX == 5) THEN
      SC1 => SCARC(1)%COMPACT(NL)
      SC2 => SCARC(2)%COMPACT(NL)
      OSC1 => SCARC(1)%OSCARC(2)%COMPACT(NL)
      OSC2 => SCARC(2)%OSCARC(1)%COMPACT(NL)
      WRITE(SCARC_LU,'(7I6,6X,6I6)') SC1%CELLTYPE(16:20),OSC1%CELLTYPE(4),OSC1%CELLTYPE(8), &
                                     OSC2%CELLTYPE(8),OSC2%CELLTYPE(4),SC2%CELLTYPE(13:16)
      WRITE(SCARC_LU,'(7I6,6X,6I6)') SC1%CELLTYPE(11:15),OSC1%CELLTYPE(3),OSC1%CELLTYPE(7), &
                                     OSC2%CELLTYPE(7),OSC2%CELLTYPE(3),SC2%CELLTYPE(9:12)
      WRITE(SCARC_LU,'(7I6,6X,6I6)') SC1%CELLTYPE(6:10) ,OSC1%CELLTYPE(2),OSC1%CELLTYPE(6), &
                                     OSC2%CELLTYPE(6),OSC2%CELLTYPE(2),SC2%CELLTYPE(5:8)
      WRITE(SCARC_LU,'(7I6,6X,6I6)') SC1%CELLTYPE(1:5)  ,OSC1%CELLTYPE(1),OSC1%CELLTYPE(5), &
                                     OSC2%CELLTYPE(5),OSC2%CELLTYPE(1),SC2%CELLTYPE(1:4)
      ELSE IF (SCARC(1)%COMPACT(1)%NX == 8) THEN
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(57:64),SC1%CELLTYPE(72),SC2%CELLTYPE(72),SC2%CELLTYPE(57:64)
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(49:56),SC1%CELLTYPE(71),SC2%CELLTYPE(71),SC2%CELLTYPE(49:56)
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(41:48),SC1%CELLTYPE(70),SC2%CELLTYPE(70),SC2%CELLTYPE(41:48)
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(33:40),SC1%CELLTYPE(69),SC2%CELLTYPE(69),SC2%CELLTYPE(33:40)
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(25:32),SC1%CELLTYPE(68),SC2%CELLTYPE(68),SC2%CELLTYPE(25:32)
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(17:24),SC1%CELLTYPE(67),SC2%CELLTYPE(67),SC2%CELLTYPE(17:24)
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(9:16) ,SC1%CELLTYPE(66),SC2%CELLTYPE(66),SC2%CELLTYPE(9:16)
      WRITE(SCARC_LU,'(9I6,6X,9I6)') SC1%CELLTYPE(1:8)  ,SC1%CELLTYPE(65),SC2%CELLTYPE(65),SC2%CELLTYPE(1:8)
      ELSE IF (SCARC(1)%COMPACT(1)%NX == 9) THEN
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(64:72),SC1%CELLTYPE(80),SC2%CELLTYPE(72),SC2%CELLTYPE(57:64)
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(55:63),SC1%CELLTYPE(79),SC2%CELLTYPE(71),SC2%CELLTYPE(49:56)
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(46:54),SC1%CELLTYPE(78),SC2%CELLTYPE(70),SC2%CELLTYPE(41:48)
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(37:45),SC1%CELLTYPE(77),SC2%CELLTYPE(69),SC2%CELLTYPE(33:40)
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(28:36),SC1%CELLTYPE(76),SC2%CELLTYPE(68),SC2%CELLTYPE(25:32)
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(19:27),SC1%CELLTYPE(75),SC2%CELLTYPE(67),SC2%CELLTYPE(17:24)
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(10:18),SC1%CELLTYPE(74),SC2%CELLTYPE(66),SC2%CELLTYPE(9:16)
      WRITE(SCARC_LU,'(10I6,6X,9I6)') SC1%CELLTYPE(1:9)  ,SC1%CELLTYPE(73),SC2%CELLTYPE(65),SC2%CELLTYPE(1:8)
      ENDIF
      IF (TYPE_DEBUG > NSCARC_DEBUG_LESS) THEN
      DO NM = NMESHES_MIN, NMESHES_MAX
         SC  => SCARC(NM)%COMPACT(NL)
         DO NOM = 1, NMESHES
            IF (NOM == NM) CYCLE 
            OS  => SCARC(NM)%OSCARC(NOM)      
            IF (OS%NICMAX_S==0 .AND. OS%NICMAX_R==0) CYCLE 
            OSC  => SCARC(NM)%OSCARC(NOM)%COMPACT(NL)      
            WRITE(SCARC_LU,'(a,i3,a,i3,a,i3)') '============= SCARC(',NM,')%OSCARC(',NOM,')%CELLTYPE:', OSC%NG
            DO IC=1,OSC%NG
               WRITE(SCARC_LU,'(i5,a,I5)') IC,':',OSC%CELLTYPE(IC)
            ENDDO
         ENDDO
      ENDDO
      ENDIF

   !!!----------------------------------------------------------------------------------------------------
   !!! Debug CELLTYPE
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_DEBUG_COARSE)

      DO NM = NMESHES_MIN, NMESHES_MAX
         WRITE(SCARC_LU,1000) CROUTINE, CNAME, NM, NL
         SC  => SCARC(NM)%COMPACT(NL)
         DO K = SC%NZ,1,-1
            DO I = 1,SC%NX
               IC = (K-1)*SC%NX + I
               IF (SC%CELLTYPE(IC) < 0) THEN
                  LINE(I:I) = 'O'
               ELSE IF (SC%CELLTYPE(IC) > 0) THEN
                  LINE(I:I) = 'X'
               ENDIF
            ENDDO
            WRITE(SCARC_LU,'(12A4)') (LINE(I:I), I=1,SC%NX)
         ENDDO
      ENDDO

END SELECT

1000 FORMAT('======================================================================================',/, &
            '=== ',A20,' : ', A25,' for mesh ',i3,' on level ', i3, /, &
            '======================================================================================')
 
END SUBROUTINE SCARC_DEBUG_QUANTITY

 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Debug full vector information on level NL 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_DEBUG_VECTOR (NVECTOR, CROUTINE, CNAME)
INTEGER, INTENT(IN):: NVECTOR
REAL (EB), POINTER, DIMENSION(:,:,:) :: VB
REAL (EB), POINTER, DIMENSION(:)     :: VC
REAL (EB):: VALUES(10)
INTEGER :: NM, II, JJ, KK, IC, NX8, NY8, NZ8
CHARACTER (*), INTENT(IN) :: CROUTINE, CNAME
TYPE (MESH_TYPE), POINTER :: M
 
IF (TYPE_DEBUG < NSCARC_DEBUG_LESS) RETURN

SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

   !!!----------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX

         M  => MESHES(NM)
         VB => POINT_TO_BVECTOR (NVECTOR, NM, NLEVEL_MIN)

         NX8=MIN(8,M%IBAR)
         NY8=MIN(8,M%JBAR)
         NZ8=MIN(8,M%KBAR)
         
         WRITE(SCARC_LU,*) '===================================================================='
         WRITE(SCARC_LU,2000) CROUTINE, CNAME, NM, NLEVEL_MIN
         WRITE(SCARC_LU,*) '===================================================================='
         SELECT_BANDED_DIMENSION: SELECT CASE (TYPE_DIMENSION)
      
            CASE (NSCARC_DIMENSION_TWO)
      
               DO KK = NZ8, 1, - 1
                  DO II=1,NX8
                     IF (ABS(VB(II,1,KK))<1.0E-14_EB) THEN
                        VALUES(II)=0.0_EB
                     ELSE
                        VALUES(II)=VB(II,1,KK)
                     ENDIF
                  ENDDO
                  WRITE(SCARC_LU, '(a,i3,a,10e13.5)') 'J= ',1,' : ',(VALUES(II), II=1, NX8)
               ENDDO
               !WRITE(SCARC_LU,*)  '------------------------------------------------',&
               !                   '---------------------------------------------------'
      
            CASE (NSCARC_DIMENSION_THREE)
               DO KK = NZ8, 1, - 1
                  WRITE(SCARC_LU,'(a,i3,a)')  '----------------------------------------  K = ', KK,&
                                              '----------------------------------------'
                  DO JJ = NY8, 1, - 1
                     DO II=1,NX8
                        IF (ABS(VB(II,JJ,KK))<1.0E-14_EB) THEN
                           VALUES(II)=0.0_EB
                        ELSE
                           VALUES(II)=VB(II,JJ,KK)
                        ENDIF
                     ENDDO
                     WRITE(SCARC_LU, '(a,i3,a,10e13.5)') 'J= ',JJ,' : ',(VALUES(II), II=1, NX8)
                  ENDDO
               ENDDO
               WRITE(SCARC_LU,*)  '------------------------------------------------',&
                                  '---------------------------------------------------'
         END SELECT SELECT_BANDED_DIMENSION
      
      ENDDO
          
   !!!----------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      !DO NM = NMESHES_MIN, NMESHES_MAX
      DO NM = NMESHES_MIN, NMESHES_MIN
   
         M  => MESHES(NM)
         VC => POINT_TO_CVECTOR (NVECTOR, NM, NLEVEL_MIN)
         
         NX8=MIN(8,M%IBAR)
         NY8=MIN(8,M%JBAR)
         NZ8=MIN(8,M%KBAR)
         
         WRITE(SCARC_LU,*) '======================================================================'
         WRITE(SCARC_LU,2000) CROUTINE, CNAME, NM, NLEVEL_MIN
         WRITE(SCARC_LU,*) '======================================================================'
         SELECT_COMPACT_DIMENSION: SELECT CASE (TYPE_DIMENSION)
         
            CASE (NSCARC_DIMENSION_TWO)
               DO KK = NZ8, 1, - 1
                  DO II=1,NX8
                     IC = (KK-1)*M%IBAR + II
                     IF (ABS(VC(IC))<1.0E-14_EB) THEN
                        VALUES(II)=0.0_EB
                     ELSE
                        VALUES(II)=VC(IC)
                     ENDIF
                  ENDDO
                  WRITE(SCARC_LU, '(a,i3,a,8e13.5)') 'J= ',1,' : ',(VALUES(II), II=1, NX8)
               ENDDO
               !WRITE(SCARC_LU,*)  '------------------------------------------------',&
               !                   '---------------------------------------------------'
         
            CASE (NSCARC_DIMENSION_THREE)
               DO KK = NZ8, 1, - 1
                  WRITE(SCARC_LU,'(a,i3,a)')  '----------------------------------------  K = ', KK,&
                                              '----------------------------------------'
                  DO JJ = NY8, 1, - 1
                     DO II=1,NX8
                        IC = (KK-1)*M%IBAR*M%JBAR + (JJ-1)*M%IBAR + II
                        IF (ABS(VC(IC))<1.0E-14_EB) THEN
                           VALUES(II)=0.0_EB
                        ELSE
                           VALUES(II)=VC(IC)
                        ENDIF
                     ENDDO
                     WRITE(SCARC_LU, '(a,i3,a,8e13.5)') 'J= ',JJ,' : ',(VALUES(II), II=1, NX8)
                  ENDDO
               ENDDO
               WRITE(SCARC_LU,*)  '------------------------------------------------',&
                                  '---------------------------------------------------'
      END SELECT SELECT_COMPACT_DIMENSION

   ENDDO

END SELECT SELECT_SYSTEM
      
2000 FORMAT('=== ',A,' : ',A,' on mesh ',I4,' on level ',I4) 
END SUBROUTINE SCARC_DEBUG_VECTOR


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Only for debugging reasons: print out vector information on level NL 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_DEBUG_LEVEL (NVECTOR, CROUTINE, CNAME, NL)
INTEGER, INTENT(IN):: NVECTOR, NL
REAL (EB), POINTER, DIMENSION(:,:,:) :: VB
REAL (EB), POINTER, DIMENSION(:)     :: VC
REAL (EB):: VALUES(0:10)
INTEGER :: NM, II, JJ, KK, IC, NX8, NY8, NZ8
CHARACTER (*), INTENT(IN) :: CROUTINE, CNAME
TYPE (SCARC_BANDED_TYPE) , POINTER :: SB
TYPE (SCARC_COMPACT_TYPE), POINTER :: SC
 
IF (TYPE_DEBUG < NSCARC_DEBUG_INFO0) RETURN

SELECT_SYSTEM: SELECT CASE (TYPE_SYSTEM)

   !!!----------------------------------------------------------------------------------------------------
   !!! Banded system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_BANDED)

      DO NM = NMESHES_MIN, NMESHES_MAX

         SB => SCARC(NM)%BANDED(NL)
         VB => POINT_TO_BVECTOR (NVECTOR, NM, NL)

         NX8=MIN(8,SB%NX)
         NY8=MIN(8,SB%NY)
         NZ8=MIN(8,SB%NZ)
         
         WRITE(SCARC_LU,*) '=========================================================='
         WRITE(SCARC_LU,2000) CROUTINE, CNAME, NM, NL, NX8, NY8, NZ8
         WRITE(SCARC_LU,*) '=========================================================='
         SELECT_BANDED_DIMENSION: SELECT CASE (TYPE_DIMENSION)
         
            CASE (NSCARC_DIMENSION_TWO)
               DO KK = NZ8, 1, - 1
                  DO II=1,NX8
                     IF (ABS(VB(II,1,KK))<1.0E-14_EB) THEN
                        VALUES(II)=0.0_EB
                     ELSE
                        VALUES(II)=VB(II,1,KK)
                     ENDIF
                  ENDDO
                  WRITE(SCARC_LU, '(a,i3,a,10e13.5)') 'J= ',1,' : ',(VALUES(II), II=1, NX8)
               ENDDO
               !WRITE(SCARC_LU,*)  '------------------------------------------------',&
               !                   '---------------------------------------------------'
      
            CASE (NSCARC_DIMENSION_THREE)
               DO KK = NZ8, 1, - 1
                  WRITE(SCARC_LU,'(a,i3,a)')  '----------------------------------------  K = ', KK,&
                                              '----------------------------------------'
                  DO JJ = NY8, 1, - 1
                     DO II=1,NX8
                        IF (ABS(VB(II,JJ,KK))<1.0E-14_EB) THEN
                           VALUES(II)=0.0_EB
                        ELSE
                           VALUES(II)=VB(II,JJ,KK)
                        ENDIF
                     ENDDO
                     WRITE(SCARC_LU, '(a,i3,a,10e13.5)') 'J= ',JJ,' : ',(VALUES(II), II=1, NX8)
                  ENDDO
               ENDDO
               WRITE(SCARC_LU,*)  '------------------------------------------------',&
                                  '---------------------------------------------------'

         END SELECT SELECT_BANDED_DIMENSION

      ENDDO
         
   !!!----------------------------------------------------------------------------------------------------
   !!! Compact system
   !!!----------------------------------------------------------------------------------------------------
   CASE (NSCARC_SYSTEM_COMPACT)

      DO NM = NMESHES_MIN, NMESHES_MAX
      !DO NM = NMESHES_MIN, NMESHES_MIN

         SC => SCARC(NM)%COMPACT(NL)
         VC => POINT_TO_CVECTOR (NVECTOR, NM, NL)
         NX8=MIN(8,SC%NX)
         NY8=MIN(8,SC%NY)
         NZ8=MIN(8,SC%NZ)

         WRITE(SCARC_LU,*) '=========================================================='
         WRITE(SCARC_LU,2001) CROUTINE, CNAME, NM, NL, SC%NC, SC%NCE
         WRITE(SCARC_LU,*) '=========================================================='
         IF (NL == NLEVEL_MIN) THEN
               DO KK = NZ8, 1, - 1
                  !WRITE(SCARC_LU,'(a,i3,a)')  '----------------------------------------  K = ', KK,&
                  !                           '----------------------------------------'
                  DO JJ = NY8, 1, - 1
                     DO II=1,NX8
                        IC = (KK-1)*SC%NX*SC%NY + (JJ-1)*SC%NY + II
                        IF (ABS(VC(IC))<1.0E-14_EB) THEN
                           VALUES(II)=0.0_EB
                        ELSE
                           VALUES(II)=VC(IC)
                        ENDIF
                     ENDDO
                     WRITE(SCARC_LU, '(a,i3,a,10e18.10)') 'J= ',JJ,' : ',(VALUES(II), II=1, NX8)
                  ENDDO
               ENDDO
               WRITE(SCARC_LU,*)  '----------------------------',&
                                  '-------------------------------'
         ELSE

         IF (NMESHES == 1) THEN
            WRITE(SCARC_LU,*) '======================================='
            WRITE(SCARC_LU,*) '============== MESH 1'
            WRITE(SCARC_LU,*) '======================================='
            WRITE(SCARC_LU,'(i4,a,f25.16)') 1,' : ', VC(1)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 2,' : ', VC(2)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 5,' : ', VC(5)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 6,' : ', VC(6)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 7,' : ', VC(7)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 10,' : ', VC(10)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 11,' : ', VC(11)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 14,' : ', VC(14)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 15,' : ', VC(15)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 16,' : ', VC(16)
            WRITE(SCARC_LU,*) '======================================='
            WRITE(SCARC_LU,*) '============== MESH 2'
            WRITE(SCARC_LU,*) '======================================='
            WRITE(SCARC_LU,'(i4,a,f25.16)') 3,' : ', VC(3)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 4,' : ', VC(4)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 8,' : ', VC(8)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 9,' : ', VC(9)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 12,' : ', VC(12)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 13,' : ', VC(13)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 17,' : ', VC(17)
            WRITE(SCARC_LU,'(i4,a,f25.16)') 18,' : ', VC(18)
            WRITE(SCARC_LU,*) '======================================='
            !WRITE(SCARC_LU,'(i4,a,f25.16)') (IC,' : ', VC(IC), IC=1,SC%NC)
            !IF (NL == 1) THEN
            !   WRITE(SCARC_LU, '(4e13.5)') (VC(IC), IC=1, SC%NC)
            !ELSE IF (NL == 2) THEN
            !   WRITE(SCARC_LU, '(2e13.5)') (VC(IC), IC=1, SC%NC)
            !ELSE IF (NL == 3) THEN
            !   WRITE(SCARC_LU, '(2e13.5)') (VC(IC), IC=1, SC%NC)
            !ENDIF
         ELSE
            WRITE(SCARC_LU,'(i4,a,f25.16)') (IC,' : ', VC(IC), IC=1,SC%NC)
            !IF (NL == 1) THEN
            !   WRITE(SCARC_LU, '(4e13.5)') (VC(IC), IC=1, SC%NC)
            !ELSE IF (NL == 2) THEN
            !   WRITE(SCARC_LU, '(2e13.5)') (VC(IC), IC=1, SC%NC)
            !ELSE IF (NL == 3) THEN
            !   WRITE(SCARC_LU, '(2e13.5)') (VC(IC), IC=1, SC%NC)
            !ENDIF
         ENDIF
         WRITE(SCARC_LU,*)  '------------------------------------------------',&
                            '---------------------------------------------------'
         ENDIF

      ENDDO

END SELECT SELECT_SYSTEM

2000 FORMAT('=== ',A,' : ',A,' on mesh ',I4,' on level ',I4, ': NX, NY, NZ=',3i3)
2001 FORMAT('=== ',A,' : ',A,' on mesh ',I4,' on level ',I4, ': NC=',3i3, ': NCE=',3i3)
END SUBROUTINE SCARC_DEBUG_LEVEL

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Produce latex information about coarsening of grid
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_LATEX_GRID(NTYPE, NL)
INTEGER, INTENT(IN) :: NTYPE, NL
INTEGER :: NM, NL0, MLATEX, I, K, IC, IC1, IC2, IC3, IC4, IC5, IC6
CHARACTER (60) :: CLATEX


SELECT CASE(NTYPE)

   !!!-------------------------------------------------------------------------------------------------
   !!! Produce Latex information about grid coarsening with different node sizes for different levels
   !!!-------------------------------------------------------------------------------------------------
   CASE(NSCARC_LATEX_STAGGERED)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         WRITE (CLATEX, '(A,A,A,i2.2,A,i2.2,A)') 'latex/',TRIM(CHID),'_mesh',NM,'_level',NL+1,'_s.tex'
         MLATEX=GET_FILE_NUMBER()
         OPEN(MLATEX,FILE=CLATEX)
         WRITE(MLATEX,1001)
         WRITE(MLATEX,2001)
      
         NL0 = NLEVEL_MIN
         DO K = SCARC(NM)%COMPACT(NL0)%NZ,1,-1
            DO I = 1,SCARC(NM)%COMPACT(NL0)%NX
               IC = (K-1)*SCARC(NM)%COMPACT(NL0)%NX + I
               WRITE(MLATEX,3002) 'L1','L1',I,K,I,K
               IC1=SCARC(NM)%COMPACT(NL0)%CELLTYPE(IC)
               IF (IC1>0) THEN
                   WRITE(MLATEX,3002) 'L2','L2',I,K,I,K
                   IF (SCARC(NM)%COMPACT(NL0)%NCC>=1) THEN
                   IF (NL==1) CYCLE
                   IC2=SCARC(NM)%COMPACT(NL0+1)%CELLTYPE(IC1)
                   IF (IC2>0) THEN
                      WRITE(MLATEX,3002) 'L3','L3',I,K,I,K
                      IF (SCARC(NM)%COMPACT(NL0+1)%NCC>=1) THEN
                      IF (NL==2) CYCLE
                      IC3=SCARC(NM)%COMPACT(NL0+2)%CELLTYPE(IC2)
                      IF (IC3>0) THEN
                         WRITE(MLATEX,3002) 'L4','L4',I,K,I,K
                         IF (SCARC(NM)%COMPACT(NL0+2)%NCC>=1) THEN
                         IF (NL==3) CYCLE
                         IC4=SCARC(NM)%COMPACT(NL0+3)%CELLTYPE(IC3)
                         IF (IC4>0) THEN
                            WRITE(MLATEX,3002) 'L5','L5',I,K,I,K
                            IF (SCARC(NM)%COMPACT(NL0+3)%NCC>=1) THEN
                            IF (NL==4) CYCLE
                            IC5=SCARC(NM)%COMPACT(NL0+4)%CELLTYPE(IC4)
                            IF (IC5>0) THEN
                               WRITE(MLATEX,3002) 'L6','L6',I,K,I,K
                               IF (SCARC(NM)%COMPACT(NL0+3)%NCC>=1) THEN
                               IF (NL==5) CYCLE
                               IC6=SCARC(NM)%COMPACT(NL0+4)%CELLTYPE(IC4)
                               IF (IC6>0) THEN
                                  WRITE(MLATEX,3002) 'L7','L7',I,K,I,K
                               ENDIF
                               ENDIF
                            ENDIF
                            ENDIF
                         ENDIF
                         ENDIF
                      ENDIF
                      ENDIF
                   ENDIF
                   ENDIF
               ENDIF
            ENDDO
         ENDDO
      
         WRITE(MLATEX,1002)
         CLOSE(MLATEX)
      
      ENDDO
      
      
   !!!-------------------------------------------------------------------------------------------------
   !!! Produce Latex information about grid coarsening with same node sizes for different levels
   !!!-------------------------------------------------------------------------------------------------
   CASE(NSCARC_LATEX_EQUAL)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         WRITE (CLATEX, '(A,A,A,i2.2,A,i2.2,A)') 'latex/',TRIM(CHID),'_mesh',NM,'_level',NL+1,'_e.tex'
         MLATEX=GET_FILE_NUMBER()
         OPEN(MLATEX,FILE=CLATEX)
         WRITE(MLATEX,1001)
         WRITE(MLATEX,3001)
      
         NL0 = NLEVEL_MIN
         DO K = SCARC(NM)%COMPACT(NL0)%NZ,1,-1
            DO I = 1,SCARC(NM)%COMPACT(NL0)%NX
               IC = (K-1)*SCARC(NM)%COMPACT(NL0)%NX + I
               WRITE(MLATEX,3002) 'L1','L1',I,K,I,K
               IC1=SCARC(NM)%COMPACT(NL0)%CELLTYPE(IC)
               IF (IC1>0) THEN
                   WRITE(MLATEX,4002) 'L2','L2',I,K,I,K, IC1
                   IF (SCARC(NM)%COMPACT(NL0)%NCC>=1) THEN
                   IF (NL==1) CYCLE
                   IC2=SCARC(NM)%COMPACT(NL0+1)%CELLTYPE(IC1)
                   IF (IC2>0) THEN
                      WRITE(MLATEX,3002) 'L3','L3',I,K,I,K
                      IF (SCARC(NM)%COMPACT(NL0+1)%NCC>=1) THEN
                      IF (NL==2) CYCLE
                      IC3=SCARC(NM)%COMPACT(NL0+2)%CELLTYPE(IC2)
                      IF (IC3>0) THEN
                         WRITE(MLATEX,3002) 'L4','L4',I,K,I,K
                         IF (SCARC(NM)%COMPACT(NL0+2)%NCC>=1) THEN
                         IF (NL==3) CYCLE
                         IC4=SCARC(NM)%COMPACT(NL0+3)%CELLTYPE(IC3)
                         IF (IC4>0) THEN
                            WRITE(MLATEX,3002) 'L5','L5',I,K,I,K
                            IF (SCARC(NM)%COMPACT(NL0+3)%NCC>=1) THEN
                            IF (NL==4) CYCLE
                            IC5=SCARC(NM)%COMPACT(NL0+4)%CELLTYPE(IC4)
                            IF (IC5>0) THEN
                               WRITE(MLATEX,3002) 'L6','L6',I,K,I,K
                               IF (SCARC(NM)%COMPACT(NL0+3)%NCC>=1) THEN
                               IF (NL==5) CYCLE
                               IC6=SCARC(NM)%COMPACT(NL0+4)%CELLTYPE(IC4)
                               IF (IC6>0) THEN
                                  WRITE(MLATEX,3002) 'L7','L7',I,K,I,K
                               ENDIF
                               ENDIF
                            ENDIF
                            ENDIF
                         ENDIF
                         ENDIF
                      ENDIF
                      ENDIF
                   ENDIF
                   ENDIF
               ENDIF
            ENDDO
         ENDDO
      
         WRITE(MLATEX,1002)
         CLOSE(MLATEX)
      
      ENDDO
      
   !!!-------------------------------------------------------------------------------------------------
   !!! Produce Latex information about grid coarsening with different node sizes for different levels
   !!!-------------------------------------------------------------------------------------------------
   CASE(NSCARC_LATEX_NUMBER)

      DO NM = NMESHES_MIN, NMESHES_MAX
      
         IF (NL == NLEVEL_MIN) THEN
            WRITE (CLATEX, '(A,A,A,i2.2,A,i2.2,A)') 'latex/',TRIM(CHID),'_mesh',NM,'_level',NL,'_n.tex'
            MLATEX=GET_FILE_NUMBER()
            OPEN(MLATEX,FILE=CLATEX)
            WRITE(MLATEX,1001)
            WRITE(MLATEX,4001)
            NL0 = NLEVEL_MIN
            DO K = SCARC(NM)%COMPACT(NL0)%NZ,1,-1
               DO I = 1,SCARC(NM)%COMPACT(NL0)%NX
                  IC = (K-1)*SCARC(NM)%COMPACT(NL0)%NX + I
!WRITE(SCARC_LU,*) 'IC=',IC,I,K
                  WRITE(MLATEX,4002) 'L1','L1',I,K,I,K, IC
               ENDDO
            ENDDO
            WRITE(MLATEX,1002)
            CLOSE(MLATEX)
         ENDIF

         WRITE (CLATEX, '(A,A,A,i2.2,A,i2.2,A)') 'latex/',TRIM(CHID),'_mesh',NM,'_level',NL+1,'_n.tex'
         MLATEX=GET_FILE_NUMBER()
         OPEN(MLATEX,FILE=CLATEX)
         WRITE(MLATEX,1001)
         WRITE(MLATEX,4001)
      
         NL0 = NLEVEL_MIN
         DO K = SCARC(NM)%COMPACT(NL0)%NZ,1,-1
            DO I = 1,SCARC(NM)%COMPACT(NL0)%NX
               IC = (K-1)*SCARC(NM)%COMPACT(NL0)%NX + I
               IC1=SCARC(NM)%COMPACT(NL0)%CELLTYPE(IC)
               IF (IC1> 0) THEN
                  WRITE(MLATEX,4002) 'L2','L2',I,K,I,K, IC1
                  IF (SCARC(NM)%COMPACT(NL0)%NCC>=1) THEN
                  IF (NL==1) CYCLE
                  IC2=SCARC(NM)%COMPACT(NL0+1)%CELLTYPE(IC1)
                  IF (IC2>0) THEN
                     WRITE(MLATEX,4002) 'L2','L2',I,K,I,K, IC2
                     IF (SCARC(NM)%COMPACT(NL0+1)%NCC>=1) THEN
                     IF (NL==2) CYCLE
                     IC3=SCARC(NM)%COMPACT(NL0+2)%CELLTYPE(IC2)
                     IF (IC3>0) THEN
                        WRITE(MLATEX,4002) 'L3','L3',I,K,I,K, IC3
                        IF (SCARC(NM)%COMPACT(NL0+2)%NCC>=1) THEN
                        IF (NL==3) CYCLE
                        IC4=SCARC(NM)%COMPACT(NL0+3)%CELLTYPE(IC3)
                        IF (IC4>0) THEN
                           WRITE(MLATEX,4002) 'L4','L4',I,K,I,K, IC4
                           IF (SCARC(NM)%COMPACT(NL0+3)%NCC>=1) THEN
                           IF (NL==4) CYCLE
                           IC5=SCARC(NM)%COMPACT(NL0+4)%CELLTYPE(IC4)
                           IF (IC5>0) THEN
                              WRITE(MLATEX,4002) 'L5','L5',I,K,I,K, IC5
                              IF (SCARC(NM)%COMPACT(NL0+3)%NCC>=1) THEN
                              IF (NL==5) CYCLE
                              IC6=SCARC(NM)%COMPACT(NL0+4)%CELLTYPE(IC4)
                              IF (IC6>0) THEN
                                 WRITE(MLATEX,4002) 'L6','L6',I,K,I,K, IC6
                                 WRITE(MLATEX,4002) 'L7','L7',I,K,I,K, IC6
                              ENDIF
                              ENDIF
                           ENDIF
                           ENDIF
                        ENDIF
                        ENDIF
                     ENDIF
                     ENDIF
                  ENDIF
                  ENDIF
               ELSE
                  WRITE(MLATEX,4002) 'L1','L1',I,K,I,K, IC1
               ENDIF
            ENDDO
         ENDDO
      
         WRITE(MLATEX,1002)
         CLOSE(MLATEX)
      
      ENDDO
END SELECT

1001 FORMAT('\documentclass[11pt]{minimal}' ,/,&
            '\usepackage{tikz}' ,/,&
            '\usetikzlibrary{positioning}' ,/,&
            '\begin{document}' ,/,&
            '\begin{tikzpicture}')
1002 FORMAT('\end{tikzpicture}',/,&
            '\end{document}')

2001 FORMAT ('[inner sep=1mm,',/,&
            ' scale=1.0,',/,&
            ' L7/.style={rectangle, draw=black!40, fill=yellow!100  , thin, minimum size=12mm},',/,&
            ' L6/.style={rectangle, draw=black!40, fill=black!80  , thin, minimum size=10mm},',/,&
            ' L5/.style={rectangle, draw=black!40, fill=blue!80 , thin, minimum size=8mm},',/,&
            ' L4/.style={rectangle, draw=black!40, fill=green!50 , thin, minimum size=6mm},',/,&
            ' L3/.style={rectangle, draw=black!40, fill=red!50   , thin, minimum size=4mm},',/,&
            ' L2/.style={rectangle, draw=black!40, fill=blue!40  , thin, minimum size=2mm},',/,&
            ' L1/.style={rectangle, draw=black!40, fill=black!02, thin, minimum size=10mm}],')
2002 FORMAT('\node [',A,']  (',A2,I2.2,i2.2,')  at (',I2,',',I2,')  {};')

3001 FORMAT ('[inner sep=0.1mm,',/,&
            ' scale=1.0,',/,&
            ' L6/.style={rectangle, draw=black!40, fill=black!80  , thin, minimum size=2mm},',/,&
            ' L5/.style={rectangle, draw=black!40, fill=blue!80 , thin, minimum size=3mm},',/,&
            ' L4/.style={rectangle, draw=black!40, fill=green!50 , thin, minimum size=5mm},',/,&
            ' L3/.style={rectangle, draw=black!40, fill=red!50   , thin, minimum size=7mm},',/,&
            ' L2/.style={rectangle, draw=black!40, fill=blue!40  , thin, minimum size=9mm},',/,&
            ' L1/.style={rectangle, draw=black!40, fill=black!02, thin, minimum size=10mm}],')
3002 FORMAT('\node [',A,']  (',A2,I2.2,i2.2,')  at (',I2,',',I2,')  {};')

4001 FORMAT ('[inner sep=1mm,',/,&
            ' scale=1.0,',/,&
            ' L7/.style={rectangle, draw=black!40, fill=yellow!100,thin, minimum size=10mm},',/,&
            ' L6/.style={rectangle, draw=black!40, fill=red!80  , thin, minimum size=10mm},',/,&
            ' L5/.style={rectangle, draw=black!40, fill=black!60 , thin, minimum size=10mm},',/,&
            ' L4/.style={rectangle, draw=black!40, fill=green!50 , thin, minimum size=10mm},',/,&
            ' L3/.style={rectangle, draw=black!40, fill=red!50   , thin, minimum size=10mm},',/,&
            ' L2/.style={rectangle, draw=black!40, fill=blue!40  , thin, minimum size=10mm},',/,&
            ' L1/.style={rectangle, draw=black!40, fill=black!02, thin, minimum size=10mm}],')
4002 FORMAT('\node [',A,']  (',A2,I2.2,i2.2,')  at (',I2,',',I2,')  {',i2,'};')
 
END SUBROUTINE SCARC_LATEX_GRID


 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Print out timings for ScaRC - not updated at the moment
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_TIMINGS
INTEGER:: NM, IERR, I
INTEGER , ALLOCATABLE, DIMENSION(:)   :: COUNTS_SCARC_TIMERS, DISPLS_SCARC_TIMERS
REAL(EB), ALLOCATABLE, DIMENSION(:,:) :: BUFFER
CHARACTER(40) :: NAME_SCARC(0:N_TIMERS_SCARC)
REAL(EB) :: TPCNT_SCARC(0:N_TIMERS_SCARC)

!!! only temporarily - use routine only in debug mode
IF (TYPE_DEBUG == NSCARC_DEBUG_NONE) RETURN

IERR=0
 
ALLOCATE(COUNTS_SCARC_TIMERS(0:NUMPROCS-1))
ALLOCATE(DISPLS_SCARC_TIMERS(0:NUMPROCS-1))
ALLOCATE(BUFFER(N_TIMERS_SCARC, NMESHES))

COUNTS_SCARC_TIMERS = COUNTS_SCARC*N_TIMERS_SCARC
DISPLS_SCARC_TIMERS = DISPLS_SCARC*N_TIMERS_SCARC

BUFFER = TUSED_SCARC
IF (USE_MPI) CALL MPI_GATHERV(TUSED_SCARC(1,DISPLS_SCARC(MYID)+1),COUNTS_SCARC_TIMERS(MYID),&
                              MPI_DOUBLE_PRECISION,TUSED_SCARC, COUNTS_SCARC_TIMERS,DISPLS_SCARC_TIMERS,&
                              MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,IERR)

!!! Printout subroutine timings
!!! outdated version, must be revised (not used at the moment)

IF (MYID==0) THEN
   NAME_SCARC                           = 'null'
   NAME_SCARC(NSCARC_TIME_TOTAL)        = 'ScaRC complete'
   NAME_SCARC(NSCARC_TIME_SETUP)        = 'ScaRC setup'
   NAME_SCARC(NSCARC_TIME_SOLVER)       = 'ScaRC solver'
   NAME_SCARC(NSCARC_TIME_KRYLOV)       = 'ScaRC Krylov method'
   NAME_SCARC(NSCARC_TIME_MULTIGRID)    = 'ScaRC multigrid method'
   NAME_SCARC(NSCARC_TIME_PRECON)       = 'ScaRC preconditioner'
   NAME_SCARC(NSCARC_TIME_SMOOTH)       = 'ScaRC smoother'
   NAME_SCARC(NSCARC_TIME_COARSE)       = 'ScaRC coarse grid solver'
   NAME_SCARC(NSCARC_TIME_MATVEC)       = 'ScaRC matrix-vector product'
   NAME_SCARC(NSCARC_TIME_SCALPROD)     = 'ScaRC scalar product'
   NAME_SCARC(NSCARC_TIME_L2NORM)       = 'ScaRC L2-norm'
   NAME_SCARC(NSCARC_TIME_EXCH_INIT)    = 'ScaRC initialization data exchange'
   NAME_SCARC(NSCARC_TIME_EXCH_VECTOR)  = 'ScaRC exchange of vector values'
   NAME_SCARC(NSCARC_TIME_EXCH_MATRIX)  = 'ScaRC exchange of matrix values'
   NAME_SCARC(NSCARC_TIME_EXCH_MEASURE) = 'ScaRC exchange of measure values'
   
   DO NM=1,NMESHES
      DO I=1,N_TIMERS_SCARC
         TPCNT_SCARC(I) = 100._EB*TUSED_SCARC(I,NM)/TUSED(1,NM)
      ENDDO
      WRITE(LU_OUTPUT,443) NM
      !WRITE(LU_OUTPUT,444) 'MAIN',TUSED(1,NM),100._EB
      WRITE(LU_OUTPUT,444) (NAME_SCARC(I),TUSED_SCARC(I,NM),TPCNT_SCARC(I),I=1,N_TIMERS_SCARC)
   ENDDO
ENDIF

   IF (TYPE_DEBUG /= NSCARC_DEBUG_NONE ) CLOSE(SCARC_LU)

443 FORMAT(//' ScaRC: CPU Time Usage, Mesh ',I3// &
         47X,' CPU (s)        %  '/ &
         7X,' -----------------------------------------------------------------')
444 FORMAT(7X,A40,2F11.2)

END SUBROUTINE SCARC_TIMINGS


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Stops the code gracefully after writing a message
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SCARC_SHUTDOWN(CMESSAGE)

CHARACTER(*) CMESSAGE
LOGICAL :: EX

WRITE(LU_ERR,'(/A)') TRIM(CMESSAGE)
INQUIRE(FILE=FN_OUTPUT,EXIST=EX)
IF (.NOT.EX) OPEN(LU_OUTPUT,FILE=TRIM(CHID)//'.out',STATUS='REPLACE',FORM='FORMATTED')
WRITE(LU_OUTPUT,'(/A)') TRIM(CMESSAGE)
STOP

END SUBROUTINE SCARC_SHUTDOWN


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Compute current revision number
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE GET_REV_SCRC(MODULE_REV,MODULE_DATE)
INTEGER,INTENT(INOUT) :: MODULE_REV
CHARACTER(255),INTENT(INOUT) :: MODULE_DATE

WRITE(MODULE_DATE,'(A)') SCRCREV(INDEX(SCRCREV,':')+2:LEN_TRIM(SCRCREV)-2)
READ (MODULE_DATE,'(I5)') MODULE_REV
WRITE(MODULE_DATE,'(A)') SCRCDATE

END SUBROUTINE GET_REV_SCRC

END MODULE SCRC
 

