################################
### Aerodynamic conductance #### 
################################

#' Aerodynamic Conductance
#' 
#' Bulk aerodynamic conductance, including options for the boundary layer conductance
#'              formulation and stability correction functions.
#' 
#' - data              Data_frame or matrix containing all required variables
#' - Tair              Air temperature (deg C)
#' - pressure          Atmospheric pressure (kPa)
#' - wind              Wind speed (m s-1)
#' - ustar             Friction velocity (m s-1)
#' - H                 Sensible heat flux (W m-2)
#' - zr                Instrument (reference) height (m)
#' - zh                Canopy height (m)
#' - d                 Zero-plane displacement height (m)
#' - z0m               Roughness length for momentum (m), optional; if not provided, it is estimated from \code{roughness_parameters}
#'                          (method="wind_profile"). Only used if \code{wind_profile = TRUE} and/or \code{Rb_model} = \code{"Su_2001"} or
#'                          \code{"Choudhury_1988"}.
#' - Dl                Characteristic leaf dimension (m) (if \code{Rb_model} = \code{"Su_2001"}) 
#'                          or leaf width (if \code{Rb_model} = \code{"Choudhury_1988"}); ignored otherwise.
#' - N                 Number of leaf sides participating in heat exchange (1 or 2); only used if \code{Rb_model = "Su_2001"}.
#'                          Defaults to 2.
#' - fc                Fractional vegetation cover (-); only used if \code{Rb_model = "Su_2001"}. See Details.
#' - LAI               One-sided leaf area index (m2 m-2); only used if \code{Rb_model} = \code{"Choudhury_1988"} or \code{"Su_2001"}.
#' - Cd                Foliage drag coefficient (-); only used if \code{Rb_model = "Su_2001"}. 
#' - hs                Roughness length of bare soil (m); only used if \code{Rb_model = "Su_2001"}.
#' - wind_profile      Should Ga for momentum be calculated based on the logarithmic wind profile equation? 
#'                          Defaults to \code{FALSE}.
#' - stab_correction   Should stability correction be applied? Defaults to \code{TRUE}. Ignored if \code{wind_profile = FALSE}.                         
#' - stab_formulation  Stability correction function. Either \code{"Dyer_1970"} (default) or
#'                          \code{"Businger_1971"}. Ignored if \code{wind_profile = FALSE} or if \code{stab_correction = FALSE}.
#' - Rb_model          Boundary layer resistance formulation. One of \code{"Thom_1972","Choudhury_1988","Su_2001","constant_kB-1"}.
#' - kB_h              kB-1 value for heat transfer; only used if \code{Rb_model = "constant_kB-1"}
#' - Sc                Optional: Schmidt number of additional quantities to be calculated
#' - Sc_name           Optional: Name of the additonal quantities, has to be of same length than 
#'                          \code{Sc_name}
#' - constants         k - von Karman constant \cr
#'                          cp - specific heat of air for constant pressure (J K-1 kg-1) \cr
#'                          Kelvin - conversion degree Celsius to Kelvin \cr
#'                          g - gravitational acceleration (m s-2) \cr
#'                          pressure0 - reference atmospheric pressure at sea level (Pa) \cr
#'                          Tair0 - reference air temperature (K) \cr
#'                          Sc_CO2 - Schmidt number for CO2 \cr 
#'                          Pr - Prandtl number (if \code{Sc} is provided)
#'
#' # Details

#' 
#' Aerodynamic conductance for heat (Ga_h) is calculated as:
#' 
#'     \deqn{Ga_h = 1 / (Ra_m + Rb_h)}
#'  
#'  where Ra_m is the aerodynamic resistance for momentum and Rb the (quasi-laminar) canopy boundary
#'  layer resistance ('excess resistance').
#'  
#'  The aerodynamic resistance for momentum Ra_m is given by:
#'  
#'     \deqn{Ra_m = u/ustar^2}
#'  
#'  Note that this formulation accounts for changes in atmospheric stability, and does not require an
#'  additional stability correction function. 
#'  
#'  An alternative method to calculate Ra_m is provided
#'  (calculated if \code{wind_profile = TRUE}):
#'  
#'     \deqn{Ra_m = (ln((zr - d)/z0m) - psi_h) / (k ustar)}
#'  
#'  If the roughness parameters z0m and d are unknown, they can be estimated using
#'  \code{\link{roughness_parameters}}. The argument \code{stab_formulation} determines the stability correction function used 
#'  to account for the effect of atmospheric stability on Ra_m (Ra_m is lower for unstable
#'  and higher for stable stratification). Stratification is based on a stability parameter zeta (z-d/L),
#'  where z = reference height, d the zero-plane displacement height, and L the Monin-Obukhov length, 
#'  calculated with \code{\link{Monin_Obukhov_length}}
#'  The stability correction function is chosen by the argument \code{stab_formulation}. Options are 
#'  \code{"Dyer_1970"} and \code{"Businger_1971"}.
#'  
#'  The model used to determine the canopy boundary layer resistance for heat (Rb_h) is specified by 
#'  the argument \code{Rb_model}. The following options are implemented:
#'  \code{"Thom_1972"} is an empirical formulation based on the friction velocity (ustar) (Thom 1972):
#'  
#'    \deqn{Rb_h = 6.2ustar^-0.667}
#'    
#'  The model by Choudhury & Monteith 1988 (\code{Rb_model = "Choudhury_1988"}),
#'  calculates Rb_h based on leaf width, LAI and ustar (Note that function argument \code{Dl}
#'  represents leaf width (w) and not characteristic leaf dimension (Dl)
#'  if \code{Rb_model} = \code{"Choudhury_1988"}):
#'   
#'     \deqn{Gb_h = LAI((0.02/\alpha)*sqrt(u(zh)/w)*(1-exp(-\alpha/2)))}
#'     
#'  where \eqn{\alpha} is a canopy attenuation coefficient modeled in dependence on LAI,
#'  u(zh) is wind speed at canopy height (calculated from \code{\link{wind_profile}}),
#'  and w is leaf width (m). See \code{\link{Gb_Choudhury}} for further details.
#'     
#'  The option \code{Rb_model = "Su_2001"} calculates Rb_h based on the physically-based Rb model by Su et al. 2001,
#'  a simplification of the model developed by Massman 1999:
#'  
#'     \deqn{kB-1 = (k Cd fc^2) / (4Ct ustar/u(zh)) + kBs-1(1 - fc)^2}
#'     
#'  where Cd is a foliage drag coefficient (defaults to 0.2), fc is fractional
#'  vegetation cover, Bs-1 is the inverse Stanton number for bare soil surface,
#'  and Ct is a heat transfer coefficient. See \code{\link{Gb_Su}} for 
#'  details on the model.
#'     
#'  
#'  The models calculate the parameter kB-1, which is related to Rb_h:
#'  
#'     \deqn{kB-1 = Rb_h * (k * ustar)}
#'  
#'  Rb (and Gb) for water vapor and heat are assumed to be equal in this package.
#'  Gb for other quantities x is calculated as (Hicks et al. 1987):
#'  
#'     \deqn{Gb_x = Gb / (Sc_x / Pr)^0.67}
#'  
#'  where Sc_x is the Schmidt number of quantity x, and Pr is the Prandtl number (0.71).
#'  
#' # Value
 a dataframe with the following columns:
#'         \item{Ga_m}{Aerodynamic conductance for momentum transfer (m s-1)}
#'         \item{Ra_m}{Aerodynamic resistance for momentum transfer (s m-1)}
#'         \item{Ga_h}{Aerodynamic conductance for heat transfer (m s-1)}
#'         \item{Ra_h}{Aerodynamic resistance for heat transfer (s m-1)}
#'         \item{Gb_h}{Canopy boundary layer conductance for heat transfer (m s-1)}
#'         \item{Rb_h}{Canopy boundary layer resistance for heat transfer (s m-1)}
#'         \item{kB_h}{kB-1 parameter for heat transfer}
#'         \item{zeta}{Stability parameter 'zeta' (NA if \code{wind_profile = FALSE})}
#'         \item{psi_h}{Integrated stability correction function (NA if \code{wind_profile = FALSE})}
#'         \item{Ra_CO2}{Aerodynamic resistance for CO2 transfer (s m-1)}
#'         \item{Ga_CO2}{Aerodynamic conductance for CO2 transfer (m s-1)}
#'         \item{Gb_CO2}{Canopy boundary layer conductance for CO2 transfer (m s-1)}
#'         \item{Ga_Sc_name}{Aerodynamic conductance for \code{Sc_name} (m s-1). Only added if \code{Sc_name} and 
#'                           the respective \code{Sc} are provided}
#'         \item{Gb_Sc_name}{Boundary layer conductance for \code{Sc_name} (m s-1). Only added if \code{Sc_name} and 
#'                           the respective \code{Sc} are provided}
#'        
#' @note The roughness length for water and heat (z0h) is not returned by this function, but 
#'       it can be calculated from the following relationship (e.g. Verma 1989):
#'       
#'       \deqn{kB-1 = ln(z0m/z0h)} 
#'       
#'       it follows:
#'       
#'       \deqn{z0h = z0m / exp(kB-1)}
#'       
#'       \code{kB-1} is an output of this function.
#'       
#'       Input variables such as LAI, Dl, or zh can be either constants, or
#'       vary with time (i.e. vectors of the same length as \code{data}).
#'       
#'       Note that boundary layer conductance to water vapor transfer (Gb_w) is often 
#'       assumed to equal Gb_h. This assumption is also made in this R package, for 
#'       example in the function \code{\link{surface_conductance}}.
#'       
#'       If the roughness length for momentum (\code{z0m}) is not provided as input, it is estimated 
#'       from the function \code{roughness_parameters} within \code{wind_profile} if \code{wind_profile = TRUE} 
#'       and/or \code{Rb_model} = \code{"Su_2001"} or \code{"Choudhury_1988"} The \code{roughness_parameters}
#'       function estimates a single \code{z0m} value for the entire time period! If a varying \code{z0m} value 
#'       (e.g. across seasons or years) is required, \code{z0m} should be provided as input argument.
#'       
#'         
#' @references Verma, S., 1989: Aerodynamic resistances to transfers of heat, mass and momentum.
#'             In: Estimation of areal evapotranspiration, IAHS Pub, 177, 13-20.
#'             
#'             Verhoef, A., De Bruin, H., Van Den Hurk, B., 1997: Some practical notes on the parameter kB-1
#'             for sparse vegetation. Journal of Applied Meteorology, 36, 560-572.
#'             
#'             Hicks, B_B., Baldocchi, D_D., Meyers, T_P., Hosker, J_R., Matt, D_R., 1987:
#'             A preliminary multiple resistance routine for deriving dry deposition velocities
#'             from measured quantities. Water, Air, and Soil Pollution 36, 311-330.
#'             
#'             Monteith, J_L., Unsworth, M_H., 2008: Principles of environmental physics.
#'             Third Edition. Elsevier Academic Press, Burlington, USA. 
#' 
#' @seealso \code{\link{Gb_Thom}}, \code{\link{Gb_Choudhury}}, \code{\link{Gb_Su}} for calculations of Rb / Gb only
#' 
#' ```@example; output = false
#' ``` 
#' df = DataFrame(Tair=25,pressure=100,wind=c(3,4,5),ustar=c(0.5,0.6,0.65),H=c(200,230,250))   
#'  
#' # simple calculation of Ga  
#' aerodynamic_conductance(df,Rb_model="Thom_1972") 
#' 
#' # calculation of Ga using a model derived from the logarithmic wind profile
#' aerodynamic_conductance(df,Rb_model="Thom_1972",zr=40,zh=25,d=17.5,z0m=2,wind_profile=TRUE) 
#' 
#' # simple calculation of Ga, but a physically based canopy boundary layer model
#' aerodynamic_conductance(df,Rb_model="Su_2001",zr=40,zh=25,d=17.5,Dl=0.05,N=2,fc=0.8)
#' 
"""
"""
function aerodynamic_conductance(data,Tair="Tair",pressure="pressure",wind="wind",ustar="ustar",H="H",
                                    zr,zh,d,z0m=NULL,Dl,N=2,fc=NULL,LAI,Cd=0.2,hs=0.01,wind_profile=FALSE,
                                    stab_correction=TRUE,stab_formulation=c("Dyer_1970","Businger_1971"),
                                    Rb_model=c("Thom_1972","Choudhury_1988","Su_2001","constant_kB-1"),
                                    kB_h=NULL,Sc=NULL,Sc_name=NULL,constants=bigleaf_constants())
  
  Rb_model         = match_arg(Rb_model)
  stab_formulation = match_arg(stab_formulation)
  
  check_input(data,list(Tair,pressure,wind,ustar,H))

  ## calculate canopy boundary layer conductance (Gb)
  if (Rb_model %in% c("Thom_1972","Choudhury_1988","Su_2001"))
    
    if (Rb_model == "Thom_1972")
      
      Gb_mod = Gb_Thom(ustar=ustar,Sc=Sc,Sc_name=Sc_name,constants=constants)
      
else if (Rb_model == "Choudhury_1988")
      
      Gb_mod = Gb_Choudhury(data,Tair=Tair,pressure=pressure,wind=wind,ustar=ustar,
                             H=H,leafwidth=Dl,LAI=LAI,zh=zh,zr=zr,d=d,z0m=z0m,
                             stab_formulation=stab_formulation,Sc=Sc,Sc_name=Sc_name,
                             constants=constants)
      
else if (Rb_model == "Su_2001")
      
      Gb_mod = Gb_Su(data=data,Tair=Tair,pressure=pressure,ustar=ustar,wind=wind,
                      H=H,zh=zh,zr=zr,d=d,z0m=z0m,Dl=Dl,N=N,fc=fc,LAI=LAI,Cd=Cd,hs=hs,
                      stab_formulation=stab_formulation,Sc=Sc,Sc_name=Sc_name,
                      constants=constants)  
      
end
    
    kB_h = Gb_mod[,"kB_h"]
    Rb_h = Gb_mod[,"Rb_h"]
    Gb_h = Gb_mod[,"Gb_h"]
    Gb_x = DataFrame(Gb_mod[,grep(colnames(Gb_mod),pattern="Gb_")[-1]])
    colnames(Gb_x) = grep(colnames(Gb_mod),pattern="Gb_",value=TRUE)[-1]

    
else if (Rb_model == "constant_kB-1")
    
    if(is_null(kB_h))
      stop("value of kB-1 has to be specified if Rb_model is set to 'constant_kB-1'!")
else 
      Rb_h = kB_h/(constants$k * ustar)
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
      
end
    
end 
  
  ## calculate aerodynamic conductance for momentum (Ga_m)
  if (wind_profile)
    
    if (is_null(z0m) & Rb_model %in% c("constant_kB-1","Thom_1972"))
      stop("z0m must be provided if wind_profile=TRUE!")
else if (is_null(z0m) & Rb_model %in% c("Choudhury_1988","Su_2001"))
      # z0m estimated as in Choudhury_1988 or Su_2001
      z0m = roughness_parameters(method="wind_profile",zh=zh,zr=zr,d=d,data=data,
                                  Tair=Tair,pressure=pressure,wind=wind,ustar=ustar,H=H,
                                  stab_roughness=TRUE,stab_formulation=stab_formulation,
                                  constants=constants)[,"z0m"]
end
    
    if (stab_correction)
      
      zeta  =  stability_parameter(data=data,Tair=Tair,pressure=pressure,ustar=ustar,
                                    H=H,zr=zr,d=d,constants=constants)
      
      if (stab_formulation %in% c("Dyer_1970","Businger_1971"))
        
        psi_h = stability_correction(zeta,formulation=stab_formulation)[,"psi_h"]
        
else 
        stop("'stab_formulation' has to be one of 'Dyer_1970' or 'Businger_1971'.
             Choose 'stab_correction = FALSE' if no stability correction should be applied.")
end
      
      Ra_m  = pmax((log((zr - d)/z0m) - psi_h),0) / (constants$k*ustar)
      
else 
        
        Ra_m  = pmax((log((zr - d)/z0m)),0) / (constants$k*ustar)
        zeta = psi_h = rep(NA_integer_,length=length(Ra_m))
        
end
    
else 
    
    if ((!missing(zr) | !missing(d) | !missing(z0m)) & Rb_model %in% c("constant_kB-1","Thom_1972"))
      warning("Provided roughness length parameters (zr,d,z0m) are not used if 'wind_profile = FALSE' (the default). Ra_m is calculated as wind / ustar^2")
end
    
    Ra_m = wind / ustar^2
    zeta = psi_h = rep(NA_integer_,length=length(Ra_m))
    
end
  
  Ga_m   = 1/Ra_m
  Ra_h   = Ra_m + Rb_h
  Ga_h   = 1/Ra_h
  Ga_x   = 1/(Ra_m + 1/Gb_x)
  Ra_CO2 = 1/Ga_x[,1]
  colnames(Ga_x) = paste0("Ga_",c("CO2",Sc_name))
  
  Gab_x = cbind(Ga_x,Gb_x)
  Gab_x = Gab_x[rep(c(1,ncol(Gab_x)-(ncol(Gab_x)/2-1)),ncol(Gab_x)/2) + sort(rep(0:(ncol(Gab_x)/2-1),2))] # reorder columns

  return(DataFrame(Ga_m,Ra_m,Ga_h,Ra_h,Gb_h,Rb_h,kB_h,zeta,psi_h,Ra_CO2,Gab_x))
  
end