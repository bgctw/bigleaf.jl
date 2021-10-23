################################################
### Boundary layer conductance formulations #### 
################################################

#' Boundary Layer Conductance according to Thom 1972
#' 
#' An empirical formulation for the canopy boundary layer conductance 
#'              for heat transfer based on a simple ustar dependency.
#' 
#' - ustar     Friction velocity (m s-1)
#' - Sc        Optional: Schmidt number of additional quantities to be calculated
#' - Sc_name   Optional: Name of the additional quantities, has to be of same length than 
#'                  \code{Sc_name}
#' - constants k - von-Karman constant \cr
#'                  Sc_CO2 - Schmidt number for CO2 \cr 
#'                  Pr - Prandtl number (if \code{Sc} is provided)
#'
#'  
#' # Details
 The empirical equation for Rb suggested by Thom 1972 is:
#'  
#'      \deqn{Rb = 6.2ustar^-0.67}
#'  
#'    Gb (=1/Rb) for water vapor and heat are assumed to be equal in this package.
#'    Gb for other quantities x is calculated as (Hicks et al. 1987):
#'  
#'      \deqn{Gb_x = Gb / (Sc_x / Pr)^0.67}
#'  
#'  where Sc_x is the Schmidt number of quantity x, and Pr is the Prandtl number (0.71).
#'  
#' # Value
 a DataFrame with the following columns:
#'  \item{Gb_h}{Boundary layer conductance for heat transfer (m s-1)}
#'  \item{Rb_h}{Boundary layer resistance for heat transfer (s m-1)}
#'  \item{kB_h}{kB-1 parameter for heat transfer}
#'  \item{Gb_Sc_name}{Boundary layer conductance for \code{Sc_name} (m s-1). Only added if \code{Sc_name} and 
#'                    \code{Sc_name} are provided}
#'  
#' @references Thom, A., 1972: Momentum, mass and heat exchange of vegetation.
#'             Quarterly Journal of the Royal Meteorological Society 98, 124-134.
#'             
#'             Hicks, B_B., Baldocchi, D_D., Meyers, T_P., Hosker, J_R., Matt, D_R., 1987:
#'             A preliminary multiple resistance routine for deriving dry deposition velocities
#'             from measured quantities. Water, Air, and Soil Pollution 36, 311-330.
#' 
#' @seealso \code{\link{Gb_Choudhury}}, \code{\link{Gb_Su}}, \code{\link{aerodynamic_conductance}}
#' 
#' ```@example; output = false
#' ``` 
#' Gb_Thom(seq(0.1,1.4,0.1))
#' 
#' ## calculate Gb for SO2 as well
#' Gb_Thom(seq(0.1,1.4,0.1),Sc=1.25,Sc_name="SO2")
#' 
"""
"""
function Gb_Thom(ustar,Sc=NULL,Sc_name=NULL,constants=bigleaf_constants())
  
  check_input(NULL,ustar)
  
  Rb_h = 6.2*ustar^-0.667
  Gb_h = 1/Rb_h
  kB_h = Rb_h*constants$k*ustar
  
  if (!is_null(Sc) | !is_null(Sc_name))
    if (length(Sc) != length(Sc_name))
      stop("arguments 'Sc' and 'Sc_name' must have the same length")
end
    if (!is_numeric(Sc))
      stop("argument 'Sc' must be numeric")
end
end
  
  Sc   = c(constants$Sc_CO2,Sc)
  Gb_x = DataFrame(lapply(Sc,function(x) Gb_h / (x/constants$Pr)^0.67))
  colnames(Gb_x) = paste0("Gb_",c("CO2",Sc_name))
  
  return(DataFrame(Gb_h,Rb_h,kB_h,Gb_x))
end




#' Boundary Layer Conductance according to Choudhury & Monteith 1988
#' 
#' A formulation for the canopy boundary layer conductance 
#'              for heat transfer according to Choudhury & Monteith 1988.
#'              
#' - data             Data_frame or matrix containing all required variables
#' - Tair             Air temperature (degC)
#' - pressure         Atmospheric pressure (kPa)
#' - wind             Wind speed at sensor height (m s-1)
#' - ustar            Friction velocity (m s-1)
#' - H                Sensible heat flux (W m-2)
#' - leafwidth        Leaf width (m)
#' - LAI              One-sided leaf area index
#' - zh               Canopy height (m)
#' - zr               Instrument (reference) height (m)
#' - d                Zero-plane displacement height (-), can be calculated using \code{roughness_parameters}
#' - z0m              Roughness length for momentum (m). If not provided, calculated from \code{roughness_parameters} 
#'                         within \code{wind_profile}
#' - stab_formulation Stability correction function used (If \code{stab_correction = TRUE}).
#'                         Either \code{"Dyer_1970"} or \code{"Businger_1971"}.
#' - Sc               Optional: Schmidt number of additional quantities to be calculated
#' - Sc_name          Optional: Name of the additonal quantities, has to be of same length than 
#'                         \code{Sc_name}
#' - constants        k - von-Karman constant \cr
#'                         Sc_CO2 - Schmidt number for CO2 \cr 
#'                         Pr - Prandtl number (if \code{Sc} is provided)
#'                         
#' # Value
 A data frame with the following columns:
#'  \item{Gb_h}{Boundary layer conductance for heat transfer (m s-1)}
#'  \item{Rb_h}{Boundary layer resistance for heat transfer (s m-1)}
#'  \item{kB_h}{kB-1 parameter for heat transfer}
#'  \item{Gb_Sc_name}{Boundary layer conductance for \code{Sc_name} (m s-1). Only added if \code{Sc_name} and 
#'                    \code{Sc_name} are provided}
#' 
#' # Details
 Boundary layer conductance according to Choudhury & Monteith 1988 is
#'          given by:
#'          
#'            \deqn{Gb_h = LAI((2a/\alpha)*sqrt(u(h)/w)*(1-exp(-\alpha/2)))}
#'          
#'          where u(zh) is the wind speed at the canopy surface, approximated from
#'          measured wind speed at sensor height zr and a wind extinction coefficient \eqn{\alpha}:
#'          
#'            \deqn{u(zh) = u(zr) / (exp(\alpha(zr/zh -1)))}.
#'          
#'          \eqn{\alpha} is modeled as an empirical relation to LAI (McNaughton & van den Hurk 1995):
#'          
#'            \deqn{\alpha = 4.39 - 3.97*exp(-0.258*LAI)}
#'          
#'          Gb (=1/Rb) for water vapor and heat are assumed to be equal in this package.
#'          Gb for other quantities x is calculated as (Hicks et al. 1987):
#'  
#'            \deqn{Gb_x = Gb / (Sc_x / Pr)^0.67}
#'  
#'          where Sc_x is the Schmidt number of quantity x, and Pr is the Prandtl number (0.71).
#'          
#' @note If the roughness length for momentum (\code{z0m}) is not provided as input, it is estimated 
#'       from the function \code{roughness_parameters} within \code{wind_profile}. This function
#'       estimates a single \code{z0m} value for the entire time period! If a varying \code{z0m} value 
#'       (e.g. across seasons or years) is required, \code{z0m} should be provided as input argument.
#'          
#' @references Choudhury, B. J., Monteith J_L., 1988: A four-layer model for the heat
#'             budget of homogeneous land surfaces. Q. J. R. Meteorol. Soc. 114, 373-398.
#'             
#'             McNaughton, K. G., Van den Hurk, B_J_J_M., 1995: A 'Lagrangian' revision of
#'             the resistors in the two-layer model for calculating the energy budget of a
#'             plant canopy. Boundary-Layer Meteorology 74, 261-288.
#'             
#'             Hicks, B_B., Baldocchi, D_D., Meyers, T_P., Hosker, J_R., Matt, D_R., 1987:
#'             A preliminary multiple resistance routine for deriving dry deposition velocities
#'             from measured quantities. Water, Air, and Soil Pollution 36, 311-330.
#'             
#' @seealso \code{\link{Gb_Thom}}, \code{\link{Gb_Su}}, \code{\link{aerodynamic_conductance}}
#'    
#' ```@example; output = false
#' ``` 
#' ## bulk canopy boundary layer resistance for a closed canopy (LAI=5) 
#' ## with large leaves (leafwdith=0.1)            
#' df = DataFrame(Tair=25,pressure=100,wind=c(3,4,5),ustar=c(0.5,0.6,0.65),H=c(200,230,250))    
#' Gb_Choudhury(data=df,leafwidth=0.1,LAI=5,zh=25,d=17.5,zr=40)
#' 
#' ## same conditions, but smaller leaves (leafwidth=0.01)
#' Gb_Choudhury(data=df,leafwidth=0.01,LAI=5,zh=25,d=17.5,zr=40) 
#' 
#' @export                                                                                                                                                                                                                                                                                    
function Gb_Choudhury(data,Tair="Tair",pressure="pressure",wind="wind",ustar="ustar",H="H",
                         leafwidth,LAI,zh,zr,d,z0m=NULL,stab_formulation=c("Dyer_1970","Businger_1971"),
                         Sc=NULL,Sc_name=NULL,constants=bigleaf_constants())
  
  stab_formulation = match_arg(stab_formulation)
  
  check_input(data,list(Tair,pressure,wind,ustar,H))
  
  alpha   = 4.39 - 3.97*exp(-0.258*LAI)

  if (is_null(z0m))
    estimate_z0m = TRUE
    z0m = NULL
else 
    estimate_z0m = FALSE
end
  
  wind_zh = wind_profile(data=data,z=zh,Tair=Tair,pressure=pressure,ustar=ustar,H=H,
                          zr=zr,estimate_z0m=estimate_z0m,zh=zh,d=d,z0m=z0m,frac_z0m=NULL,
                          stab_correction=TRUE,stab_formulation=stab_formulation)
  
  ## avoid zero windspeed
  wind_zh = pmax(0.01,wind_zh)
  
  if (!is_null(Sc) | !is_null(Sc_name))
    if (length(Sc) != length(Sc_name))
      stop("arguments 'Sc' and 'Sc_name' must have the same length")
end
    if (!is_numeric(Sc))
      stop("argument 'Sc' must be numeric")
end
end
  
  Gb_h = LAI*((0.02/alpha)*sqrt(wind_zh/leafwidth)*(1-exp(-alpha/2)))
  Rb_h = 1/Gb_h
  kB_h = Rb_h*constants$k*ustar
  
  Sc   = c(constants$Sc_CO2,Sc)
  Gb_x = DataFrame(lapply(Sc,function(x) Gb_h / (x/constants$Pr)^0.67))
  colnames(Gb_x) = paste0("Gb_",c("CO2",Sc_name))
  
  
  return(DataFrame(Gb_h,Rb_h,kB_h,Gb_x))
end






#' Boundary Layer Conductance according to Su et al. 2001
#' 
#' A physically based formulation for the canopy boundary layer conductance
#'              to heat transfer according to Su et al. 2001. 
#'
#' - data      Data_frame or matrix containing all required variables
#' - Tair      Air temperature (degC)
#' - pressure  Atmospheric pressure (kPa)
#' - ustar     Friction velocity (m s-1)
#' - wind      Wind speed (m s-1)
#' - H         Sensible heat flux (W m-2)
#' - zh        Canopy height (m)
#' - zr        Reference height (m)
#' - d         Zero-plane displacement height (-), can be calculated using \code{roughness_parameters}
#' - z0m       Roughness length for momentum (m). If not provided, calculated from \code{roughness_parameters} 
#'                  within \code{wind_profile}
#' - Dl        Leaf characteristic dimension (m)
#' - fc        Fractional vegetation cover [0-1] (if not provided, calculated from LAI)
#' - LAI       One-sided leaf area index (-)
#' - N         Number of leaf sides participating in heat exchange (defaults to 2)
#' - Cd        Foliage drag coefficient (-)
#' - hs        Roughness height of the soil (m)
#' - stab_formulation Stability correction function used (If \code{stab_correction = TRUE}).
#'                         Either \code{"Dyer_1970"} or \code{"Businger_1971"}.
#' - Sc        Optional: Schmidt number of additional quantities to be calculated
#' - Sc_name   Optional: Name of the additional quantities, has to be of same length than 
#'                  \code{Sc_name}
#' - constants Kelvin - conversion degree Celsius to Kelvin \cr
#'                  pressure0 - reference atmospheric pressure at sea level (Pa) \cr
#'                  Tair0 - reference air temperature (K) \cr
#'                  Sc_CO2 - Schmidt number for CO2 \cr 
#'                  Pr - Prandtl number (if \code{Sc} is provided)
#' 
#' # Value
 A DataFrame with the following columns:
#'  \item{Gb_h}{Boundary layer conductance for heat transfer (m s-1)}
#'  \item{Rb_h}{Boundary layer resistance for heat transfer (s m-1)}
#'  \item{kB_h}{kB-1 parameter for heat transfer}
#'  \item{Gb_Sc_name}{Boundary layer conductance for \code{Sc_name} (m s-1). Only added if \code{Sc_name} and 
#'                    \code{Sc_name} are provided}
#'     
#' # Details
 The formulation is based on the kB-1 model developed by Massman 1999. 
#'          Su et al. 2001 derived the following approximation:
#'           
#'            \deqn{kB-1 = (k Cd fc^2) / (4Ct ustar/u(zh)) + kBs-1(1 - fc)^2}
#'          
#'          If fc (fractional vegetation cover) is missing, it is estimated from LAI:
#' 
#'            \deqn{fc = 1 - exp(-LAI/2)}
#'          
#'          The wind speed at the top of the canopy is calculated using function
#'          \code{\link{wind_profile}}.
#'          
#'          Ct is the heat transfer coefficient of the leaf (Massman 1999):
#'          
#'            \deqn{Ct = Pr^-2/3 Reh^-1/2 N}
#'          
#'          where Pr is the Prandtl number (set to 0.71), and Reh is the Reynolds number for leaves:
#'          
#'            \deqn{Reh = Dl wind(zh) / v}
#'           
#'          kBs-1, the kB-1 value for bare soil surface, is calculated according 
#'          to Su et al. 2001:
#'          
#'            \deqn{kBs^-1 = 2.46(Re)^0.25 - ln(7.4)}
#'          
#'          Gb (=1/Rb) for water vapor and heat are assumed to be equal in this package.
#'          Gb for other quantities x is calculated as (Hicks et al. 1987):
#'  
#'            \deqn{Gb_x = Gb / (Sc_x / Pr)^0.67}
#'  
#'          where Sc_x is the Schmidt number of quantity x, and Pr is the Prandtl number (0.71).
#' 
#' @note If the roughness length for momentum (\code{z0m}) is not provided as input, it is estimated 
#'       from the function \code{roughness_parameters} within \code{wind_profile}. This function
#'       estimates a single \code{z0m} value for the entire time period! If a varying \code{z0m} value 
#'       (e.g. across seasons or years) is required, \code{z0m} should be provided as input argument.
#' 
#' 
#' @references Su, Z., Schmugge, T., Kustas, W. & Massman, W., 2001: An evaluation of
#'             two models for estimation of the roughness height for heat transfer between
#'             the land surface and the atmosphere. Journal of Applied Meteorology 40, 1933-1951.
#' 
#'             Massman, W., 1999: A model study of kB H- 1 for vegetated surfaces using
#'            'localized near-field' Lagrangian theory. Journal of Hydrology 223, 27-43.
#'            
#'             Hicks, B_B., Baldocchi, D_D., Meyers, T_P., Hosker, J_R., Matt, D_R., 1987:
#'             A preliminary multiple resistance routine for deriving dry deposition velocities
#'             from measured quantities. Water, Air, and Soil Pollution 36, 311-330.
#' 
#' @seealso \code{\link{Gb_Thom}}, \code{\link{Gb_Choudhury}}, \code{\link{aerodynamic_conductance}}
#' 
#' ```@example; output = false
#' ``` 
#' # Canopy boundary layer resistance (and kB-1 parameter) for a set of meteorological conditions,
#' # a leaf characteristic dimension of 1cm, and an LAI of 5
#' df = DataFrame(Tair=25,pressure=100,wind=c(3,4,5),ustar=c(0.5,0.6,0.65),H=c(200,230,250)) 
#' Gb_Su(data=df,zh=25,zr=40,d=17.5,Dl=0.01,LAI=5)
#' 
#' # the same meteorological conditions, but larger leaves
#' Gb_Su(data=df,zh=25,zr=40,d=17.5,Dl=0.1,LAI=5)
#' 
#' # same conditions, large leaves, and sparse canopy cover (LAI = 1.5)
#' Gb_Su(data=df,zh=25,zr=40,d=17.5,Dl=0.1,LAI=1.5)
#' 
"""
"""
function Gb_Su(data,Tair="Tair",pressure="pressure",ustar="ustar",wind="wind",
                  H="H",zh,zr,d,z0m=NULL,Dl,fc=NULL,LAI=NULL,N=2,Cd=0.2,hs=0.01,
                  stab_formulation=c("Dyer_1970","Businger_1971"),
                  Sc=NULL,Sc_name=NULL,constants=bigleaf_constants())
  
  stab_formulation = match_arg(stab_formulation)
  
  check_input(data,list(Tair,pressure,ustar,wind,H))
  
  if (is_null(fc))
    if (is_null(LAI))
      stop("one of 'fc' or 'LAI' must be provided",call.=FALSE)
else 
      fc = (1-exp(-LAI/2)) 
end
end 
  
  if (is_null(z0m))
    estimate_z0m = TRUE
    z0m = NULL
else 
    estimate_z0m = FALSE
end
  
  wind_zh = wind_profile(data=data,z=zh,Tair=Tair,pressure=pressure,ustar=ustar,H=H,
                          zr=zr,estimate_z0m=estimate_z0m,zh=zh,d=d,z0m=z0m,frac_z0m=NULL,
                          stab_correction=TRUE,stab_formulation=stab_formulation)
  
  v   = kinematic_viscosity(Tair,pressure,constants)
  Re  = Reynolds_Number(Tair,pressure,ustar,hs,constants)
  kBs = 2.46 * (Re)^0.25 - log(7.4)
  Reh = Dl * wind_zh / v
  Ct  = 1*constants$Pr^-0.6667*Reh^-0.5*N
  
  kB_h = (constants$k*Cd)/(4*Ct*ustar/wind_zh)*fc^2 + kBs*(1 - fc)^2
  Rb_h = kB_h/(constants$k*ustar)
  Gb_h = 1/Rb_h
  
  if (!is_null(Sc) | !is_null(Sc_name))
    if (length(Sc) != length(Sc_name))
      stop("arguments 'Sc' and 'Sc_name' must have the same length")
end
    if (!is_numeric(Sc))
      stop("argument 'Sc' must be numeric")
end
end
  
  Sc   = c(constants$Sc_CO2,Sc)
  Gb_x = DataFrame(lapply(Sc,function(x) Gb_h / (x/constants$Pr)^0.67))
  colnames(Gb_x) = paste0("Gb_",c("CO2",Sc_name))
  
  return(DataFrame(Gb_h,Rb_h,kB_h,Gb_x))
end
