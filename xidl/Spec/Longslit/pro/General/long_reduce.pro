;+
; NAME:
;   long_reduce
;
; PURPOSE:
;
;   Main program for the Low-redux pipeline.  This set of algorithms
;   runs mainly as a black box.
;
; CALLING SEQUENCE:
;  long_reduce, planfile, /clobber, /NOZAP, /NOFLEX, /NOHELIO 
;
; INPUTS:
;  planfile  -- File created by long_plan which guides the reduction
;               process
;
; OPTIONAL INPUTS:
; /NOFLEX  -- Do not apply flexure correction [necessary if your setup
;             has not been calibrated.  Contact JH or JXP for help if
;             this is the case.]
;  HAND_FWHM -- Set the FWHM of the object profile to this value (in
;               pixels)
;  PROF_NSIGMA= -- Extend the region to fit a profile by hand 
; /NOHELIO -- Do not correct to heliocentric velocities
; /NOZAP   -- Do not flag CRs
; /NOLOCAL -- Do not do local sky subtraction
; LINELIST=  -- File for arc calibration lines
; REID_FILE=  -- File for cross-correlation [Replaces the default].
;                Note you should set BIN_RATIO when doing this.
; BIN_RATIO=  -- Ratio of binning in the data over the binning of the archived arc
; ARC_INTER=  -- Fiddle with the wavelengths interactively:  
;                1 -- Run x_identify with the archive template 
;                2 -- Run x_identify without it
; TWEAK_ARC=  -- Array of slits to be reanalyzed (using ARC_INTER=1)
; PROCARC      -- The input arc has been fully processed (usually a
;                combined arc) [FLAG]
; /PIXFLAT_ARCHIVE -- If needed and it exists, use an archived pixelflat. 
; /GMOSLONG   -- Running XGMOS in Longslit
; TRIM_SEDGE=  -- Trim each slit edge by amount inputted.  Must be
;                 done at the top level (i.e. before slit file is
;                 made)
; /JUSTCALIB -- just reduce the calibration files
; /JUSTSCI -- just reduce the science frames
; /JUSTSTD -- just reduce the standard-star observations
; /CLOBBER -- overwrite all existing files (implies /CALIBCLOBBER and /SCICLOBBER)
; /CALIBCLOBBER -- overwrite existing superbias frames, pixel flats,
;   slit structures, and wavelength solutions
; /SCICLOBBER -- overwrite existing standard and science frames
; 
; OUTPUTS:
;  (1) Various calibration files
;  (2) One multi-extension FITS file in Science per exposure containing
;  the extracted data and processed images
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;   
; PROCEDURES CALLED:
;
; BUGS:
;   
; REVISION HISTORY:
;   11-Mar-2005  Written by JH + SB
;-  
;-----------------------------------------------------------------------------
PRO long_reduce, planfile, clobber = clobber, verbose = verbose $
                 , NOFLEX = noflex1, NOZAP = NOZAP1, NOVAC = NOVAC1 $
                 , NOHELIO = NOHELIO1 $
                 , PROF_NSIGMA = PROF_NSIGMA1, SKYTRACE = SKYTRACE1 $
                 , MAXOBJ = MAXOBJ1 $
                 , NOSHIFT = NOSHIFT1, STD = STD1 $
                 , PSF_CR_FUDGE = PSF_CR_FUDGE1, NSIGMA_CR = NSIGMA_CR1 $
                 , ONLYSCI = ONLYSCI, HAND_X = HAND_X, HAND_Y = HAND_Y $
                 , HAND_FWHM = HAND_FWHM, LINELIST = linelist $
                 , REID_FILE= REID_FILE, TRIM_SEDGE=trim_sedge $
                 , REMOVE_OVERLAP=remove_overlap $
                 , USAGE = USAGE, FILESTD = FILESTD1, CHK = CHK $
                 , JUSTCALIB= JUSTCALIB, JUSTSCI= JUSTSCI, JUSTSTD= JUSTSTD $
                 , CALIBCLOBBER= CALIBCLOBBER, SCICLOBBER= SCICLOBBER $ $
                 , TRCCHK = TRCCHK, BIN_RATIO = bin_ratio $
                 , ISLIT = ISLIT1, EDIT_SEDGE_FIL=EDIT_SEDGE_FIL $
                 , ADD_SLITS = ADD_SLITS, SPLIT_SLITS = SPLIT_SLITS $
                 , COMBINE_SLITS = COMBINE_SLITS $
                 , ARC_INTER = arc_inter, PROCARC = procarc $
                 , TWEAK_ARC = tweak_arc, PIXFLAT_ARCHIVE = pixflat_archive $
                 , _EXTRA = extra 

  if  KEYWORD_SET(USAGE) THEN BEGIN
      print,'Syntax - ' + $
        'long_reduce, planfile, /CLOBBER, /VERBOSE, /NOFLEX, /NOHELIO [v1.0]' 
      return
  endif 

if (NOT keyword_set(planfile)) then planfile = findfile('plan*.par')

   ;----------
   ; If multiple plan files exist, then call this script recursively
   ; for each such plan file.

   if planfile[0] EQ '' then begin
      print, 'could not find plan file'
      print, 'try running long_plan'
      return
   endif

   if (n_elements(planfile) GT 1) then begin
      for i=0L, n_elements(planfile)-1L do begin
          splog, '------------------------'
          splog, 'Reducing ' + planfile[i]
          splog, '------------------------'
          long_reduce, planfile[i], clobber = clobber, verbose = verbose $
                       , NOFLEX = noflex1, NOZAP = NOZAP1, NOVAC = NOVAC1, NOHELIO = NOHELIO1 $
                       , PROF_NSIGMA = PROF_NSIGMA1, SKYTRACE = SKYTRACE1, MAXOBJ = MAXOBJ1 $ 
                       , NOSHIFT = NOSHIFT1, STD = STD1 $
                       , PSF_CR_FUDGE = PSF_CR_FUDGE1, NSIGMA_CR = NSIGMA_CR1 $
                       , ONLYSCI = ONLYSCI, HAND_X = HAND_X, HAND_Y = HAND_Y $
                       , HAND_FWHM = HAND_FWHM, LINELIST = linelist $
                       , REID_FILE = REID_FILE $
                       , USAGE = USAGE, FILESTD = FILESTD1, CHK = CHK $
                       , JUSTCALIB= JUSTCALIB, JUSTSCI= JUSTSCI, JUSTSTD= JUSTSTD $
                       , CALIBCLOBBER= CALIBCLOBBER, SCICLOBBER= SCICLOBBER $
                       , TRCCHK = TRCCHK, BIN_RATIO = bin_ratio $
                       , ISLIT = ISLIT1 $
                       , ARC_INTER = arc_inter, PROCARC = procarc $
                       , TWEAK_ARC = tweak_arc, PIXFLAT_ARCHIVE = pixflat_archive $
                       , _EXTRA = extra 
      endfor
      return
  endif

   ;----------
   ; Read the plan file

   planstr = yanny_readone(planfile, hdr=planhdr, /anonymous)
   planhdr = strcompress(planhdr)
   if (NOT keyword_set(planstr)) then begin
       splog, 'Empty plan file ', planfile
       return
   endif

   ;; Truncate the gz stuff
   nfil = n_elements(planstr)
   for qq=0L,nfil-1 do begin
       slen = strlen(planstr[qq].filename)
       if strmid(planstr[qq].filename,slen-3) EQ '.gz' then $
         planstr[qq].filename = strmid(planstr[qq].filename,0,slen-3)
   endfor
   logfile = yanny_par(planhdr, 'logfile')
   plotfile = yanny_par(planhdr, 'plotfile')
   indir = yanny_par(planhdr, 'indir')
   tempdir = yanny_par(planhdr, 'tempdir')
   scidir  = yanny_par(planhdr, 'scidir')
   minslit1 = long(yanny_par(planhdr, 'minslit'))
   slitthresh1 =  float(yanny_par(planhdr, 'slitthresh'))
   reduxthresh = float(yanny_par(planhdr, 'reduxthresh'))
   sig_thresh = float(yanny_par(planhdr, 'sig_thresh'))
   nolocal = long(yanny_par(planhdr, 'nolocal'))
   slity1_1 = float(yanny_par(planhdr, 'slity1'))
   slity2_1 = float(yanny_par(planhdr, 'slity2'))
   maxflex1 = float(yanny_par(planhdr, 'maxflex'))
   maxgood = long(yanny_par(planhdr, 'maxgood'))
;   ksize_1  = yanny_par(planhdr, 'slitksize')
   box_rad1 = float(yanny_par(planhdr, 'box_rad'))
   IF n_elements(MAXOBJ1) GT 0 THEN MAXOBJ = MAXOBJ1 $
   ELSE maskobj = long(yanny_par(planhdr, 'maxobj'))
   IF n_elements(SKYTRACE1) GT 0 THEN SKYTRACE = SKYTRACE1 $
   ELSE skytrace = long(yanny_par(planhdr, 'skytrace'))
   IF n_elements(NOFLEX1) GT 0 THEN NOFLEX = NOFLEX1 $
   ELSE noflex = long(yanny_par(planhdr, 'noflex'))
   IF n_elements(NOHELIO1) GT 0 THEN NOHELIO = NOHELIO1 $
   ELSE nohelio = long(yanny_par(planhdr, 'nohelio'))
   IF n_elements(NOSHIFT1) GT 0 THEN NOSHIFT = NOSHIFT1 $
   ELSE noshift = long(yanny_par(planhdr, 'noshift'))
   IF n_elements(PROF_NSIGMA1) GT 0 THEN PROF_NSIGMA = PROF_NSIGMA1 $
   ELSE prof_nsigma = float(yanny_par(planhdr, 'prof_nsigma'))
   IF n_elements(STD1) GT 0 THEN STD = STD1 $
   ELSE STD = long(yanny_par(planhdr, 'std'))
   IF n_elements(PSF_CR_FUDGE1) GT 0 THEN PSF_CR_FUDGE = PSF_CR_FUDGE1 $
   ELSE PSF_CR_FUDGE = float(yanny_par(planhdr, 'psf_cr_fudge'))
   IF n_elements(NOZAP1) GT 0 THEN NOZAP = NOZAP1 $
   ELSE NOZAP = float(yanny_par(planhdr, 'nozap'))
   IF n_elements(NOVAC1) GT 0 THEN NOVAC = NOVAC1 $
   ELSE NOVAC = float(yanny_par(planhdr, 'novac'))
   IF n_elements(NSIGMA_CR1) GT 0 THEN NSIGMA_CR = NSIGMA_CR1 $
   ELSE NSIGMA_CR = float(yanny_par(planhdr, 'nsigma_cr'))
   IF n_elements(ISLIT1) GT 0 THEN ISLIT = ISLIT1 $
   ELSE ISLIT = long(yanny_par(planhdr, 'islit'))


   IF KEYWORD_SET(slity1_1) THEN slity1 = long(slity1_1)
   IF KEYWORD_SET(slity2_1) THEN slity2 = long(slity2_1)
;   IF KEYWORD_SET(ksize_1) THEN ksize = long(ksize_1)
   IF KEYWORD_SET(box_rad1) THEN box_rad = long(box_rad1)
   IF KEYWORD_SET(minslit1) THEN minslit = long(minslit1)
   IF KEYWORD_SET(maxflex1) THEN maxflex = long(maxflex1)

   if keyword_set(clobber) then begin
      calibclobber = 1          ; for backwards compatibility - jm11jun08ucsd
      sciclobber = 1
   endif
   
   ;----------
   ; Create science dir
   IF keyword_set(scidir) THEN spawn, '\mkdir -p '+scidir

   ;----------
   ; Open log file
   if (keyword_set(logfile)) then begin
       splog, filename = logfile
       splog, 'Log file ' + logfile + ' opened ' + systime()
   endif
   splog, 'IDL version: ' + string(!version,format='(99(a," "))')
   spawn, 'uname -a', uname
   splog, 'UNAME: ' + uname[0]
   splog, 'idlutils version ' + idlutils_version()
   splog, 'Longslit version ' + longslit_version()
   
   plotfile = 0
   if (keyword_set(plotfile)) then begin
       thisfile = findfile(plotfile, count = ct)
       IF (ct EQ 0 OR KEYWORD_SET(CLOBBER)) THEN BEGIN
           splog, 'Plot file ' + plotfile
           dfpsplot, plotfile, /color
       ENDIF ELSE BEGIN
           cpbackup, plotfile
           splog, 'Plot file already exists. Creating backup'
           splog, 'Plot file ' + plotfile
           dfpsplot, plotfile, /color
       ENDELSE
   ENDIF
   
   ;----------
   ; Loop over each INSTRUMENT (e.g., CCD)

   ccd_list = planstr.instrument
   ccd_list = ccd_list[uniq(ccd_list, sort(ccd_list))]
   nccd = n_elements(ccd_list)

   for iccd=0L, nccd-1L do begin
      indx = where(planstr.instrument EQ ccd_list[iccd])

      ;;-----------------------------
      ;; Make a superbias if possible
      ;;-----------------------------
    
      ii = where(planstr[indx].flavor EQ 'bias', nbias)
      if (nbias GT 0) then begin
          ibias = indx[ii]
          superbiasfile = 'superbias-' + planstr[ibias[0]].filename
          thisfile = findfile(superbiasfile, count = ct)
          if (ct EQ 0 OR keyword_set(calibclobber)) then begin
              splog, 'Generating superbias for INSTRUMENT=', ccd_list[iccd]
              long_superbias $
                , djs_filepath(planstr[ibias].filename $
                               , root_dir = indir) $
                , superbiasfile, verbose = verbose
          endif else begin
              splog, 'Do not overwrite existing superbias ', thisfile
          endelse
      endif else begin
          superbiasfile = ''
          splog, 'No input biases for superbias for INSTRUMENT=', $
                 ccd_list[iccd]
      endelse
          
      ; Loop over each GRATING+MASK+WAVE for this INSTRUMENT
    
      mask_list = planstr[indx].grating 
    ; + planstr[indx].wave + planstr[indx].maskname $
      mask_list = mask_list[uniq(mask_list, sort(mask_list))]
      nmask = n_elements(mask_list)
          
      for imask = 0L, nmask-1L do begin
          jndx = indx[ where(planstr[indx].grating  EQ mask_list[imask]) ]
              
          qboth = planstr[jndx].flavor EQ 'bothflat'
          qtwi = (planstr[jndx].flavor EQ 'twiflat') OR qboth
          qpix = (planstr[jndx].flavor EQ 'domeflat' OR $
                   planstr[jndx].flavor EQ 'iflat') OR qboth
;          iflat = where(qtwi OR qdome)
          itwi  = where(qtwi, ntwi)
          ipix  = where(qpix, npix)
          iboth = WHERE(qtwi OR qpix, nboth)
         ;;---------------------------
         ;; Find the slits on the mask and create slitmask file 
         ;;---------------------------
          if (npix GT 0 OR ntwi GT 0) then begin
              ;; Use twiflats if possible, otherwise domeflats.
              ;; (Use only the first such file).
              if (ntwi GT 0) then ithis = jndx[itwi[0]] $
              else ithis = jndx[ipix[0]] 
              slitfile = 'slits-' + planstr[ithis].filename
              thisfile = findfile(slitfile, count = ct)
              if (ct EQ 0 OR keyword_set(calibclobber)) then begin
                  splog, 'Generating slits for INSTRUMENT=', ccd_list[iccd], $
                         ' GRATING+MASK+WAVE=', mask_list[imask]
                  IF KEYWORD_SET(SLITTHRESH1) THEN BEGIN
                      slitthresh = double(slitthresh1) 
                      nfind = 0
                  ENDIF ELSE IF $
                    strmatch(planstr[ithis].MASKNAME, '*long*') THEN BEGIN
                      slitthresh = 0.15D
                      ;; JXP -- Allow for LRISb  5/30/08
                      if strmatch(strtrim(ccd_list[iccd],2),'LRISBLUE') then $
                        nfind = 2 else begin
                          ;; Red side (allow for new chips)
                          
                          hdr = xheadfits(djs_filepath(planstr[ithis].filename,$
                                                      root_dir=indir))
                          if strmid(sxpar(hdr,'DATE'),10) LT '2009-07-01' then $
                            nfind = 1 else nfind = 2
                      endelse
                  ENDIF ELSE BEGIN
                      slitthresh = 0.02
                      nfind = 0
                  ENDELSE
                  long_slitmask, djs_filepath(planstr[ithis].filename, $
                                              root_dir = indir) $
                                 , slitfile, minslit = minslit $
                                 , GMOSLONG = gmoslong $
                                 , peakthresh = slitthresh $
                                 , y1 = slity1, y2 = slity2 $
                                 , ksize = ksize, nfind = nfind $
                                 , biasfile = superbiasfile, verbose = verbose $
                                 , TRIM_SEDGE=trim_sedge $
                                 , EDIT_SEDGE_FIL = EDIT_SEDGE_FIL $
                                 , ADD_SLITS = add_slits $
                                 , SPLIT_SLITS = split_slits $
                                 , COMBINE_SLITS = combine_slits
              endif else begin
                  splog, 'Do not overwrite existing slitmask file ', $
                         thisfile
              endelse
          endif else begin
              slitfile = ''
              splog, 'No input flats for slitmask for INSTRUMENT=', $
                     ccd_list[iccd], ' GRATING+MASK+WAVE=', mask_list[imask]
          endelse

         ;---------------------------
         ; Make a wavelength solution
         ;---------------------------

         ;; reduce all the arcs
         ii = where(planstr[jndx].flavor EQ 'arc', narc)
         if (narc GT 0) then begin
             iarc = jndx[ii]
             for jarc = 0, narc-1 do begin ; jm09dec19ucsd
                wavefile = 'wave-' + planstr[iarc[jarc]].filename
                if strpos(wavefile,'.fits') LT 0 then wavefile=wavefile+'.fits'
                thisfile = findfile(wavefile, count = ct)
                if keyword_set(TWEAK_ARC) then begin
                    ipos = strpos(wavefile,'.fits')
                    dumf = strmid(wavefile,0,ipos)+'.sav'
                    thisdum = findfile(dumf, count = ct2)
                    if ct2 EQ 0 then begin
                        splog, 'long_reduce: You must have an existing ' + $
                               'arc solution to input TWEAK_ARC.  Returning...'
                        stop
                        return
                    endif
                    calibCLOBBER=1
                endif
                if (ct EQ 0 OR keyword_set(calibclobber)) then begin
                    splog, 'Generating wavelengths for INSTRUMENT=' $
                           , ccd_list[iccd], $
                           ' GRATING+MASK+WAVE=', mask_list[imask]
                    long_wavesolve $
                      , djs_filepath(planstr[iarc[jarc]].filename $
                                     , root_dir = indir), wavefile $
                      , slitfile = slitfile, biasfile = superbiasfile $
                      , verbose = verbose, LINELIST = linelist, CHK = CHK $
                      , REID_FILE=reid_file, BIN_RATIO=bin_ratio, $
                      ARC_INTER=arc_inter, PROCARC=procarc, TWEAK_ARC=tweak_arc
                endif else begin
                    splog, 'Do not overwrite existing wavelength file ', thisfile
                endelse
             endfor
         endif else begin
             wavefile = ''
             splog, 'No input arcs for wavelengths for INSTRUMENT=', $
                    ccd_list[iccd], ' GRATING+MASK+WAVE=', mask_list[imask]
         endelse


         ;;------------------------------------
         ;; Make  pixel and illumination flats 
         ;;------------------------------------
         IF ((npix GT 0) OR (ntwi GT 0) or keyword_set(PIXFLAT_ARCHIVE)) and $
           (not strmatch(planstr[0].instrument,'GMOS-NX')) AND $
           (not strmatch(planstr[0].instrument,'GMOS-SX')) THEN BEGIN 
             IF npix GT 0 THEN BEGIN
                 pixflatfile = 'pixflat-' + planstr[jndx[ipix[0]]].filename
                 thispixflatfile = findfile(pixflatfile, count = pixct)
             ENDIF ELSE begin 
                 if keyword_set(PIXFLAT_ARCHIVE) then begin
                     long_pixflat_archive, planstr[iarc[0]], pixflatfile, pixct, $
                       ROOT=indir
                     thispixflatfile = pixflatfile
                 endif else pixct = 0
             ENDELSE
             IF ntwi GT 0 THEN BEGIN
                 illumflatfile = 'illumflat-' + planstr[jndx[itwi[0]]].filename
                 thisillumflatfile = findfile(illumflatfile, count = illumct)
             ENDIF ELSE illumct = 0
             if keyword_set(calibCLOBBER) then begin  ;; JXP 30 Mar 2010
                 pixct = 0
                 illumct = 0
             endif
             if (pixct EQ 0 OR illumct EQ 0) then begin
                 ;; Higher order for MMT illumination effect
                 ;; F strmatch(ccd_list[0], 'MMT*') OR $
                 ;;  strmatch(ccd_list[0], 'DEIMOS*') THEN npoly = 7L
                 splog, 'Generating pixel flat for INSTRUMENT=' $
                        , ccd_list[iccd], ' GRATING+MASK+WAVE=' $
                        , mask_list[imask]
                 IF illumct EQ 0 AND pixct EQ 0 THEN BEGIN
                     infiles =  djs_filepath(planstr[jndx[iboth]].filename $
                                             , root_dir = indir)
                     use_illum = qtwi[iboth] 
                     use_pixel = qpix[iboth] 
                 ENDIF ELSE IF illumct EQ 1 AND pixct EQ 0 THEN BEGIN
                     infiles =  djs_filepath(planstr[jndx[ipix]].filename $
                                             , root_dir = indir)
                     use_illum = lonarr(npix)
                     use_pixel = lonarr(npix) + 1L
                     splog, 'Do not overwrite existing illumination flat ' $
                            , thisillumflatfile
                 ENDIF ELSE IF illumct EQ 0 AND pixct EQ 1 THEN BEGIN
                     if ntwi NE 0 then begin 
                         infiles =  djs_filepath(planstr[jndx[itwi]].filename $
                                                 , root_dir = indir) 
                         use_illum = lonarr(ntwi) + 1L
                         use_pixel = lonarr(ntwi)
                     endif else begin
                        infiles =  $
                           djs_filepath(planstr[jndx[ipix[0]]].filename $
                                        , root_dir = indir) 
                         use_illum = 0L
                         use_pixel = 0L
                      endelse
                     splog, 'Do not overwrite existing pixel flats ' $
                            , thispixflatfile
                 ENDIF
                 long_superflat, infiles, pixflatfile, illumflatfile $
                                 , slitfile = slitfile $
                                 , wavefile = wavefile $
                                 , biasfile = superbiasfile $
                                 , verbose = verbose $
                                 , tempdir = tempdir $
                                 , use_illum = use_illum $
                                 , _EXTRA = extra $
                                 , use_pixel = use_pixel $
                                 , npoly = npoly, CHK = CHK
             ENDIF ELSE BEGIN
                 splog, 'Do not overwrite existing pixel flats ' $
                        , thispixflatfile
                 splog, 'Do not overwrite existing illumination flat ' $
                        , thisillumflatfile
             ENDELSE
         endif else begin
             pixflatfile = ''
             splog, 'No input pixel flats or illum flats for INSTRUMENT=', $
                    ccd_list[iccd], ' GRATING+MASK=', mask_list[imask]
         endelse

; optionally return after reducing the calibration frames
          if keyword_set(justcalib) then continue ; jm09dec19ucsd  
          
;-----------------------------------
; allow the optional of reducing the standards and science frames
; separately; jm09dec19ucsd
;-----------------------------------
         planstr1 = planstr ; need this outside the IF statement(s)
         if keyword_set(juststd) then begin 
            planstr1 = planstr
            keep = where(strtrim(planstr1.flavor,2) eq 'std',nkeep)
            if (nkeep eq 0) then begin
               splog, 'No standards observed'
               return
            endif
            planstr = planstr1[keep]
            indx = where(planstr.instrument EQ ccd_list[iccd])
            jndx = indx[ where(planstr[indx].grating  EQ mask_list[imask]) ]
            nozap = 1 ; very important!!!!
         endif

         if keyword_set(justsci) then begin
; choose a standard star as a trace crutch
            istd = where(planstr[jndx].flavor EQ 'std', nstd)
            IF nstd GT 0 THEN BEGIN
               stdfile = 'std-' + planstr[jndx[istd[0]]].filename
               thisstdfile = findfile(scidir+'/' + stdfile + '*', count = ct1)
               IF ct1 GT 0 THEN filestd = thisstdfile[0]
            endif

; crop the plan to just include the science objects
            planstr1 = planstr
            keep = where(strtrim(planstr1.flavor,2) eq 'science',nkeep)
            if (nkeep eq 0) then begin
               splog, 'No science objects observed'
               return
            endif
            planstr = planstr1[keep]
            indx = where(planstr.instrument EQ ccd_list[iccd])
            jndx = indx[ where(planstr[indx].grating  EQ mask_list[imask]) ]
         endif
         
         ;-----------------------------------
         ; Finally, reduce each science image
         ;-----------------------------------

         ii = where(planstr[jndx].flavor EQ 'science' OR $
                    planstr[jndx].flavor EQ 'std', nsci)
         ;;if keyword_set(ISLIT) and not keyword_set(ONLYSCI) then begin 
         ;;   print, 'Choose a science frame!'  
         ;;Dont redo the Std frame with ISLIT
         ;;stop
         ;;endif 

; jm11jun09ucsd - assign wavelength map by RA,DEC
         allarc = where(planstr1.flavor EQ 'arc',nallarc)
         if (nallarc gt 0) then begin
            arcra = dblarr(nallarc)
            arcdec = dblarr(nallarc)
            for iarc = 0, narc-1 do begin
               archdr = xheadfits(indir+strtrim(planstr1[allarc[iarc]].filename,2))
               ra1 = sxpar(archdr,'RA',count=racount)
               dec1 = sxpar(archdr,'DEC',count=deccount)
               if (racount eq 0) or (deccount eq 0) then begin
                  splog, 'WARNING: Insufficient header information to choose an ARC!' 
                  break
               endif
               arcra[iarc] = 15D*hms2dec(ra1)
               arcdec[iarc] = hms2dec(dec1)
            endfor 
         endif         
         
         for isci = 0L, nsci-1 do begin
             j = jndx[ii[isci]]
             IF KEYWORD_SET(ONLYSCI) THEN $
               IF strmatch(ONLYSCI, planstr[j].FILENAME) NE 1 THEN CONTINUE
             if planstr[j].flavor EQ 'science' then $
               scifile = djs_filepath('sci-' + planstr[j].filename $
                                      , root_dir = scidir) $
             else scifile = djs_filepath('std-' + planstr[j].filename $
                                      , root_dir = scidir)
             ipos = strpos(scifile, '.fits')
             if ipos LT 0 then scifile = scifile+'.fits'

             IF KEYWORD_SET(PROFILE) THEN $
               profile_filename = 'profile-' + planstr[j].filename $
             ELSE PROFILE_FILENAME= 0
             thisfile = findfile(scifile+'*', count = ct)
             if (ct EQ 0 OR keyword_set(sciclobber)) THEN BEGIN
                 splog, 'Reducing science frame ', prelog = planstr[j].filename
                 IF KEYWORD_SET(FILESTD1) THEN filestd = filestd1 $
                 ELSE IF planstr[j].flavor EQ 'science' then begin
                     istd = where(planstr[jndx].flavor EQ 'std', nstd)
                     IF nstd GT 0 THEN BEGIN
                         stdfile = 'std-' + planstr[jndx[istd[0]]].filename
                         thisstdfile = findfile(scidir+'/' + stdfile + $
                                                '*', count = ct1)
                         IF ct1 GT 0 THEN filestd = thisstdfile[0] 
                     ENDIF 
                 ENDIF 
; assign a wavelength map (brittle)
                 if (nallarc gt 0) then begin
                    if (racount and deccount) then begin
                       objhdr = xheadfits(indir+'/'+strtrim(planstr[j].filename,2))
                       objra = 15D*hms2dec(sxpar(objhdr,'RA'))
                       objdec = hms2dec(sxpar(objhdr,'DEC'))
                       mindiff = min(djs_diff_angle(arcra,arcdec,objra,objdec),windx)
                       wavefile = 'wave-'+planstr1[allarc[windx]].filename
                       splog, 'Choosing WAVEFILE '+wavefile
                    endif
                 endif 

                 long_reduce_work, djs_filepath(planstr[j].filename $
                                                , root_dir = indir), scifile $
                                   , slitfile = slitfile $
                                   , wavefile = wavefile $
                                   , biasfile = superbiasfile $
                                   , pixflatfile = pixflatfile $
                                   , illumflatfile = illumflatfile $
                                   , verbose = verbose $
                                   , maxobj = maxobj, box_rad = box_rad $
                                   , reduxthresh = reduxthresh $
                                   , sig_thresh = sig_thresh $
                                   , noflex = noflex, NOZAP = NOZAP $
                                   , maxflex = maxflex , MAXGOOD=maxgood $
                                   , NOHELIO = NOHELIO $
                                   , NOVAC=NOVAC, NITER=NITER $
                                   ;, profile_filename = profile_filename $
                                   , HAND_X = HAND_X, HAND_Y = HAND_Y $
                                   , HAND_FWHM = HAND_FWHM $
                                   , PROF_NSIGMA=PROF_NSIGMA $
                                   , FILESTD = FILESTD $
                                   , STD = (planstr[j].flavor EQ 'std') $
                                   , ISLIT = ISLIT, CHK = CHK $
                                   , TRCCHK = TRCCHK, NOLOCAL=nolocal $
                                   , NOSHIFT = NOSHIFT, SKYTRACE = SKYTRACE $
                                   , _EXTRA = extra
                 splog, prelog = ''
             endif else begin
                 splog, 'Do not overwrite existing science frame ', scifile
             endelse
         endfor
   endfor                       ; End loop over GRATING+MASK
   endfor ; End loop over INSTRUMENT

   if (keyword_set(plotfile)) then begin
       dfpsclose
   endif
   
   splog, /close
   x_psclose
   
   return
end
;------------------------------------------------------------------------------
