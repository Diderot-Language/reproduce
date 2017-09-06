/*
** epsdraw.c: draw (to EPS) dots and paths over a gray-scale image
** Copyright (C) 2017  University of Chicago
**
** This stand-along executable can be compiled with:
**   gcc -W -I$TEEM/include -L$TEEM/lib/ epsdraw.c -o epsdraw -lteem -lpng -lz -lbz2 -lm
** where TEEM_INSTALL is where Teem's lib and include directories have been installed
*/
#include <stdio.h>
#include <teem/meet.h>

int main(int argc, const char *argv[]) {
  char *err; /* all these are standard for hest */
  const char *me = argv[0];
  airArray *mop = airMopNew();
  hestParm *hparm = hestParmNew();
  hestOpt *hopt = NULL;

  Nrrd *nxy, *nlen, *nimg; /* things to learn from commandline */
  float radscl[2], yrgb[4], mmmm[4], scale;
  int transpose;

  /* build up command-line parser */
  airMopAdd(mop, hparm, AIR_CAST(airMopper, hestParmFree), airMopAlways);
  hestOptAdd(&hopt, NULL, "img", airTypeOther, 1, 1, &nimg, NULL,
             "8-bit RGB oriented image", NULL, NULL, nrrdHestNrrd);
  hestOptAdd(&hopt, NULL, "xy", airTypeOther, 1, 1, &nxy, NULL,
             "list of XY positions. Without \"-len\", this is all the "
             "dot positions; with \"-len\", these are the vertices of "
             "streamlines", NULL, NULL, nrrdHestNrrd);
  hestOptAdd(&hopt, "len", "len", airTypeOther, 1, 1, &nlen, "",
             "for drawing streamlines, list of per-path pairs of ints: "
             "the starting index of the path, and the number of points "
             "in the path",
             NULL, NULL, nrrdHestNrrd);
  hestOptAdd(&hopt, "rs", "rad scl", airTypeFloat, 2, 2, radscl, "1 0.7",
             "outer radius dots (or width of lines), and scaling < 1 of "
             "inner dot (or line) relative to outer");
  hestOptAdd(&hopt, "gc", "y r g b", airTypeFloat, 4, 4, yrgb, "1 0 0 0",
             "gray of outer dot/line, color of inner dot/line");
  hestOptAdd(&hopt, "mm", "x0 y0 x1 y1", airTypeFloat, 4, 4, mmmm,
             "nan nan nan nan",
             "different bounding box, rather than one determined by image, "
             "in same order as in PostScript: minX minY maxX, maxY");
  hestOptAdd(&hopt, "s", "scale", airTypeFloat, 1, 1, &scale, "1",
             "overall scaling");
  hestOptAdd(&hopt, "t", "tranpose", airTypeInt, 0, 0, &transpose, NULL,
             "swap X and Y in image (flip all diagonal)");
  hestParseOrDie(hopt, argc-1, argv+1, hparm, me,
                 "draw (to EPS) dots and paths over a gray-scale image",
                 AIR_TRUE, AIR_TRUE, AIR_TRUE);
  airMopAdd(mop, hopt, AIR_CAST(airMopper, hestOptFree), airMopAlways);
  airMopAdd(mop, hopt, AIR_CAST(airMopper, hestParseFree), airMopAlways);

  /* checking on inputs */
  if (!(3 == nimg->dim && nrrdTypeUChar == nimg->type
        && 3 == nimg->axis[0].size)) {
    fprintf(stderr, "%s: for img, need 3-D 3-by-X-by-Y %s array, not %u-D %u-by-? %s\n", me,
            airEnumStr(nrrdType, nrrdTypeUChar),
            nimg->dim, (unsigned int)(nimg->axis[0].size),
            airEnumStr(nrrdType, nimg->type));
    hestUsage(stderr, hopt, me, hparm);
    airMopError(mop);
    return 1;
  }
  double orient[9];
  ELL_3M_SET(orient,
             nimg->axis[1].spaceDirection[0], nimg->axis[2].spaceDirection[0], nimg->spaceOrigin[0],
             nimg->axis[1].spaceDirection[1], nimg->axis[2].spaceDirection[1], nimg->spaceOrigin[1],
             0.0,                             0.0,                             1.0);
  if (!ELL_3M_EXISTS(orient)) {
    fprintf(stderr, "%s: image not fully oriented\n", me);
    hestUsage(stderr, hopt, me, hparm);
    airMopError(mop);
    return 1;
  }
  if (!(2 == nxy->dim && nrrdTypeFloat == nxy->type)) {
    fprintf(stderr, "%s: for xy, need 2-D %s array, not %u-D %s array\n", me,
            airEnumStr(nrrdType, nrrdTypeFloat),
            nxy->dim, airEnumStr(nrrdType, nxy->type));
    hestUsage(stderr, hopt, me, hparm);
    airMopError(mop);
    return 1;
  }
  if (nlen) {
    if (!(2 == nlen->dim && nrrdTypeInt == nlen->type
          && 2 == nlen->axis[0].size )) {
      fprintf(stderr, "%s: for len, need 2-D 2-by-N %s array, not %u-D %u-by-? %s\n", me,
              airEnumStr(nrrdType, nrrdTypeInt),
              nlen->dim, (unsigned int)(nlen->axis[0].size),
              airEnumStr(nrrdType, nlen->type));
      hestUsage(stderr, hopt, me, hparm);
      airMopError(mop);
      return 1;
    }
  }

  unsigned int si;
  unsigned int sx = nimg->axis[1].size;
  unsigned int sy = nimg->axis[2].size;
  double tcol[3], ivec[3], utow[9]; /* from unit index-space to world-space */
  double xcol[3], ycol[3], dcol[3];
  ELL_3V_SET(ivec, sx, 0, 0);
  ELL_3MV_MUL(xcol, orient, ivec);
  ELL_3V_SET(ivec, 0, sy, 0);
  ELL_3MV_MUL(ycol, orient, ivec);
  ELL_3V_SET(ivec, -0.5, -0.5, 1);
  ELL_3MV_MUL(tcol, orient, ivec);
  ELL_3M_SET(utow,
             xcol[0], ycol[0], tcol[0],
             xcol[1], ycol[1], tcol[1],
             xcol[2], ycol[2], tcol[2]);
  double minX, maxX, minY, maxY;
  if (ELL_4V_EXISTS(mmmm)) {
    minX = mmmm[0];
    minY = mmmm[1];
    maxX = mmmm[2];
    maxY = mmmm[3];
  } else {
    /* tcol still useful */
    minX = maxX = tcol[0];
    minY = maxY = tcol[1];
    ELL_3V_SET(ivec, (float)sx-0.5, -0.5, 1); ELL_3MV_MUL(tcol, orient, ivec);
    minX = AIR_MIN(minX, tcol[0]); maxX = AIR_MAX(maxX, tcol[0]); minY = AIR_MIN(minY, tcol[1]);  maxY = AIR_MAX(maxY, tcol[1]);
    ELL_3V_SET(ivec, (float)sx-0.5, (float)sy-0.5, 1); ELL_3MV_MUL(tcol, orient, ivec);
    minX = AIR_MIN(minX, tcol[0]); maxX = AIR_MAX(maxX, tcol[0]); minY = AIR_MIN(minY, tcol[1]);  maxY = AIR_MAX(maxY, tcol[1]);
    ELL_3V_SET(ivec, -0.5, (float)sy-0.5, 1); ELL_3MV_MUL(tcol, orient, ivec);
    minX = AIR_MIN(minX, tcol[0]); maxX = AIR_MAX(maxX, tcol[0]); minY = AIR_MIN(minY, tcol[1]);  maxY = AIR_MAX(maxY, tcol[1]);
  }
  minX *= scale;
  minY *= scale;
  maxX *= scale;
  maxY *= scale;
  double midX = (minX + maxX)/2;
  double midY = (minY + maxY)/2;
  double hafX = (maxX - minX)/2;
  double hafY = (maxY - minY)/2;
  if (transpose) {
    minX = midX - hafY;
    maxX = midX + hafY;
    minY = midY - hafX;
    maxY = midY + hafX;
  }
  FILE *fout = stdout;
  fprintf(fout, "%%!PS-Adobe-3.0 EPSF-3.0\n");
  fprintf(fout, "%%%%Creator: GLK\n");
  fprintf(fout, "%%%%Title: drawdots\n");
  fprintf(fout, "%%%%Pages: 1\n");
  fprintf(fout, "%%%%BoundingBox: %d %d %d %d\n",
          (int)floor(minX), (int)floor(minY),
          (int)ceil(maxX), (int)ceil(maxY));
  fprintf(fout, "%%%%HiResBoundingBox: %g %g %g %g\n",
          minX, minY, maxX, maxY);
  fprintf(fout, "%%%%EndComments\n");
  fprintf(fout, "%%%%BeginProlog\n");
  fprintf(fout, "%% linestr creates empty string to hold one scanline\n");
  fprintf(fout, "/linestr %d string def\n", sx*3);
  fprintf(fout, "%%%%EndProlog\n");
  fprintf(fout, "%%%%Page: 1 1\n");
  fprintf(fout, "gsave\n");
  fprintf(fout, "%g %g moveto\n", minX, minY);
  fprintf(fout, "%g %g lineto\n", maxX, minY);
  fprintf(fout, "%g %g lineto\n", maxX, maxY);
  fprintf(fout, "%g %g lineto\n", minX, maxY);
  fprintf(fout, "closepath clip\n");
  fprintf(fout, "gsave newpath\n");
  if (transpose) {
    fprintf(fout, "%g %g translate\n", midX, midY);
    fprintf(fout, "45 rotate\n");
    fprintf(fout, "-1 1 scale\n");
    fprintf(fout, "-45 rotate\n");
    fprintf(fout, "%g %g translate\n", -midX, -midY);
  }
  fprintf(fout, "%g %g scale\n", scale, scale);
  fprintf(fout, "gsave\n");
  fprintf(fout, "[%g %g %g %g %g %g] concat\n",
          utow[0], utow[3],
          utow[1], utow[4],
          utow[2], utow[5]);
  fprintf(fout, "%d %d 8\n", sx, sy);
  fprintf(fout, "[%d 0 0 %d 0 0]\n", sx, sy);
  fprintf(fout, "{currentfile linestr readhexstring pop} "
          "false 3 colorimage\n");
  /* needed for hex writer (no non-default parms are set) */
  NrrdIoState *nio = nrrdIoStateNew();
  airMopAdd(mop, nio, (airMopper)nrrdIoStateNix, airMopAlways);
  if (nrrdEncodingHex->write(fout, nimg->data,
                             sx*sy*3, nimg, nio)) {
    airMopAdd(mop, err=biffGetDone(NRRD), airFree, airMopAlways);
    fprintf(stderr, "%s: trouble writing image data:%s", me, err);
    airMopError(mop); return 1;
  }
  fprintf(fout, "\n");
  fprintf(fout, "grestore\n");

  float *xy = AIR_CAST(float *, nxy->data);
  unsigned pi;
  if (!nlen) { /* drawing dots */
    if (radscl[1] < 1) {
      for (pi=0; pi<nxy->axis[1].size; pi++) {
        printf("%g setgray\n", yrgb[0]);
        printf("%g %g %g 0 360 arc closepath fill\n", xy[0 + 2*pi], xy[1 + 2*pi], radscl[0]);
      }
    }
    for (pi=0; pi<nxy->axis[1].size; pi++) {
      printf("%g %g %g setrgbcolor\n", yrgb[1], yrgb[2], yrgb[3]);
      printf("%g %g %g 0 360 arc closepath fill\n", xy[0 + 2*pi], xy[1 + 2*pi], radscl[0]*radscl[1]);
    }
  } else { /* drawing paths */
    fprintf(fout, "2 setlinecap\n");
    fprintf(fout, "0 setlinejoin\n");
    int *len = AIR_CAST(int *, nlen->data);
    unsigned int si, segnum = AIR_CAST(unsigned int, nlen->axis[1].size);
    for (si=0; si<segnum; si++) {
      int pi, ibase, di;
      ibase = len[0 + 2*si];
      unsigned int passIdx;
      for (passIdx=0; passIdx<2; passIdx++) {
        if (!passIdx) {
          fprintf(fout, "0 setgray\n");
          fprintf(fout, "%g setlinewidth\n", radscl[0]);
        } else {
          fprintf(fout, "1 setgray\n");
          fprintf(fout, "%g setlinewidth\n", radscl[0]*radscl[1]);
        }
        /* first point on path */
        printf("%g %g moveto\n", xy[0 + 2*ibase], xy[1 + 2*ibase]);
        for (pi=1; pi<len[1 + 2*si]; pi++) {
          di = ibase + pi;
          printf("%g %g lineto\n", xy[0 + 2*di], xy[1 + 2*di]);
        }
        printf("stroke\n");
        if (passIdx) {
          pi -= 1;
          printf("newpath\n");
          di = ibase + pi - 3;
          printf("%g %g moveto\n", xy[0 + 2*di], xy[1 + 2*di]);
          di = ibase + pi - 2;
          printf("%g %g lineto\n", xy[0 + 2*di], xy[1 + 2*di]);
          di = ibase + pi - 1;
          printf("%g %g lineto\n", xy[0 + 2*di], xy[1 + 2*di]);
          printf("closepath fill\n");
        }
      }
    }
  }
  fprintf(fout, "grestore\n");
  fprintf(fout, "grestore\n");
  airMopOkay(mop);
  return 0;
}
