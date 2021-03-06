function synth_lte_stokesv, which_line, mu, atmosphere, line, spectral, Intensity, operation_mode
common ATMDAT,w,ab,ei1,ei2,sym

	
	PK = 1.3806503d-16
	UMA = 1.66053873d-24
	PE0 = 4.8032d-10
	PC = 2.99792458d10
	PME = 9.10938188d-28
	PH = 6.62606876d-27
	OPA = !DPI * PE0^2 / (PME * PC)
	alpha_cte = PE0 / (4.d0*!DPI*PME*PC^2)
	
	atmdat,1	
	
	n = n_elements(atmosphere.T)
	
; Calculate optical depth at 5000 A
	z = atmosphere.z
	T = atmosphere.T
	Pe = atmosphere.Pe
	nH = atmosphere.nH
	vmic = atmosphere.vmic
	vmac = atmosphere.vmac
	Bz = atmosphere.Bz
	
	opa500 = kappa_c(Pe,T,5000.d0,htoverv)
	opa500 = opa500 * htoverv
	
	tau500 = fltarr(n)
	for i = n-2, 0, -1 do begin
		tau500[i] = tau500[i+1] + 0.5d0*(opa500[i+1]+opa500[i]) * abs(z[i+1]-z[i])
	endfor
	
; Read lines
	element = line.element
	ioniz = line.ioniz
	lambda0 = line.lambda0
	nu0 = line.nu0
	Elow = line.Elow
	gf = line.gf
	alpha_ABO = line.alpha_ABO
	sigma_ABO = line.sigma_ABO
	lambda_from = line.lambda_from
	lambda_to = line.lambda_to
	lambda_step = line.lambda_step
	
	masa = w[element-1]
			
	doppler_width = sqrt(2.d0*PK*T/(masa*UMA)+vmic^2)
	
; Carry out the synthesis
	if (operation_mode eq 'synth') then begin
		nlambda = (lambda_to-lambda_from)/lambda_step + 1
		lambda = findgen(nlambda) * lambda_step + lambda_from
		spectral = create_struct('lambda',lambda)
	endif
	if (operation_mode eq 'inver') then begin
		lambda = spectral.lambda
		nlambda = n_elements(lambda)
	endif
	nu = PC / (lambda*1.d-8)
	
	eta = fltarr(nlambda,n)
	etaC = fltarr(nlambda,n)
	epsilon = fltarr(nlambda,n)
	epsilonC = fltarr(nlambda,n)

	damping = fltarr(n)
	opacityL = fltarr(n)
	
; Continuum opacity
	opacityC = kappa_c(Pe,T,lambda0,htoverv)
	opacityC = opacityC * htoverv
	
; Boundary condition
	I0 = plancknu(T[0],nu)
	
; Calculate line opacity at each depth
	for i = 0, n-1 do begin				
		damping[i] = calcdamping(T[i], Pe[i], nH[i], lambda0, $
			doppler_width[i], alpha=alpha_ABO, sigma0=sigma_ABO, mass=masa)
											
		partition, T[i], element, u1, u2, u3
		n1overn0 = saha(T[i], Pe[i], u1, u2, ei1[element-1])
		n2overn1 = saha(T[i], Pe[i], u2, u3, ei2[element-1])
		
		case ioniz of
			1 : begin
					niovern = 1.d0 / (1.d0 + n1overn0 + n2overn1 * n1overn0)
         		ui = u1
         	 end
         2 : begin
         		niovern = 1.d0 / (1.d0 + 1.d0/n1overn0 + n2overn1)
         		ui = u2
         	 end
      	else : begin
      				print, 'Unknown ionization state'
      				stop
      			 end
      endcase
		
		opacityL[i] = OPA * gf / ui * exp(-Elow/(PK * T[i])) * $
			(1.d0 - exp(-PH/PK * nu0 / T[i])) * niovern * nH[i] * ab[element-1]
			
		dnu = nu0 * doppler_width[i] / PC
		
		doppler_shift = nu0 * vmac[i] / PC

		v = (nu-nu0) / dnu
		va = doppler_shift / dnu
		prof = fvoigt(damping[i], v-va)

		dprofile_dl = -PC / (line.lambda0*1.d-8)^2 / (dnu^2 * sqrt(!DPI)) * 2.d0 * (-(v-va) * prof[0,*] + damping[i] * prof[1,*])
		
		eta[*,i] = opacityC[i] + opacityL[i] * prof[0,*] / (dnu * sqrt(!DPI))
		
 		epsilon[*,i] = alpha_cte * line.gbar * (line.lambda0*1.d-8)^2 * Bz[i] * opacityL[i] * dprofile_dl * (Intensity[*,i]-plancknu(T[i],nu))
				
	endfor
	
	res = shortcar_poly(z, eta, epsilon, mu, replicate(0.d0,nlambda))
	spec = res[*,n-1]
		
	return, reform(spec)
end