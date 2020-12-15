# frozen_string_literal: true

require_relative '../spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../../lib/mini_kraken/glue/dsl'


module MiniKraken
  module Glue
    describe 'DSL (Chap 1)' do
      include DSL

      context 'Chapter 1 examples:' do
        it 'passes frame 1:7' do
          # (run* q #u) ;; => ()

          result = run_star('q', _fail)
          expect(result).to be_null
        end

        it 'passes frame 1:10' do
          # (run* q (== 'pea 'pod) ;; => ()

          result = run_star('q', unify(:pea, :pod))
          expect(result).to be_null
        end

        it 'passes frame 1:11' do
          # (run* q (== q 'pea) ;; => (pea)

          result = run_star('q', unify(q, :pea))
          expect(result.car).to eq(:pea)
        end

        it 'passes frame 1:12' do
          # Reasoned S2, frame 1:12
          # (run* q (== 'pea q) ;; => (pea)

          result = run_star('q', unify(:pea, q))
          expect(result.car).to eq(:pea)
        end

        it 'passes frame 1:17' do
          # (run* q succeed) ;; => (_0)

          result = run_star('q', succeed)
          expect(result.car).to eq(:_0)
        end

        it 'passes frame 1:19' do
          # Reasoned S2, frame 1:19
          # (run* q (== 'pea 'pea)) ;; => (_0)

          result = run_star('q', unify(:pea, :pea))
          expect(result.car).to eq(:_0)
        end

        it 'passes frame 1:20' do
          # (run* q (== q q)) ;; => (_0)

          result = run_star('q', unify(q, q))
          expect(result.car).to eq(:_0)
        end

        it "supports 'fresh' and passes frame 1:21" do
          # Reasoned S2, frame 1:21
          # (run* q (fresh (x) (== 'pea q))) ;; => (pea)

          result = run_star('q', fresh('x', unify(:pea, q)))
          expect(result.car).to eq(:pea)
        end

        it 'passes frame 1:25' do
          # (run* q
          #   (fresh (x)
          #     (== (cons x '()) q))) ;; => ((_0))

          result = run_star('q', fresh('x', unify(cons(x, null_list), q)))
          expect(result.car.to_s).to eq('(_0)')
        end

        it 'passes frame 1:31' do
          # (run* q (fresh (x) (== x q))) ;; => (_0)

          result = run_star('q', fresh('x', unify(x, q)))
          expect(result.car).to eq(:_0)
        end

        it 'passes frame 1:32' do
          # (run* q (==  '(((pea)) pod) '(((pea)) pod))) ;; => (_0)

          result = run_star('q', unify(cons(cons(:pea), :pod), cons(cons(:pea), :pod)))
          expect(result.car).to eq(:_0)
        end

        it 'passes frame 1:33' do
          # Beware: quasiquoting
          # (run* q (==  '(((pea)) pod) '(((pea)) ,q))) ;; => ('pod)

          result = run_star('q', unify(cons(cons(:pea), :pod), cons(cons(:pea), q)))
          expect(result.car).to eq(:pod)
        end

        it 'passes frame 1:34' do
          # (run* q (==  '(((,q)) pod) `(((pea)) pod))) ;; => ('pea)

          expr1 = cons(cons(cons(q)), cons(:pod))
          expect(expr1.to_s).to eq('(((q)) :pod)')
          expr2 = cons(cons(cons(:pea)), cons(:pod))
          expect(expr2.to_s).to eq('(((:pea)) :pod)')
          result = run_star('q', unify(expr1, expr2))
          expect(result.car).to eq(:pea)
        end

        it 'passes frame 1:35' do
          # (run* q (fresh (x) (==  '(((,q)) pod) `(((,x)) pod)))) ;; => (_0)

          result = run_star('q', fresh('x', unify(cons(cons(q), :pod), cons(cons(x), :pod))))
          expect(result.car).to eq(:_0)
        end

        it 'passes frame 1:36' do
          # (run* q (fresh (x) (==  '(((,q)) ,x) `(((,x)) pod)))) ;; => ('pod)

          expr1 = cons(cons(cons(q)), cons(x))
          expect(expr1.to_s).to eq('(((q)) x)')
          expr2 = cons(cons(cons(x)), cons(:pod))
          expect(expr2.to_s).to eq('(((x)) :pod)')
          result = run_star('q', fresh('x', unify(expr1, expr2)))
          expect(result.car).to eq(:pod)
        end

        it 'passes frame 1:37' do
          # (run* q (fresh (x) (==  '( ,x ,x) q))) ;; => (_0 _0)

          result = run_star('q', fresh('x', unify(cons(x, cons(x)), q)))
          expect(result.car).to eq(cons(:_0, cons(:_0)))
        end

        it 'passes frame 1:38' do
          # (run* q (fresh (x) (fresh (y) (==  '( ,q ,y) '((,x ,y) ,x))))) ;; => (_0 _0)

          result = run_star('q', fresh('x', fresh('y', unify(cons(q, cons(y)), cons(cons(x, cons(y)), cons(x))))))
          expect(result.car).to eq(cons(:_0, cons(:_0)))
        end

        it 'passes frame 1:41' do
          # Reasoned S2, frame 1:41
          # (run* q (fresh (x) (fresh (y) (==  '( ,x ,y) q)))) ;; => (_0 _1)

          result = run_star('q', fresh('x', fresh('y', unify(cons(x, cons(y)), q))))
          # q should be bound to '(,x ,y)
          expect(result.car).to eq(cons(:_0, cons(:_1)))
        end

        it 'passes frame 1:42' do
          # (run* s (fresh (t) (fresh (u) (==  '( ,t ,u) s)))) ;; => (_0 _1)

          result = run_star('s', fresh('t', fresh('u', unify(cons(t, cons(u)), s))))
          # s should be bound to '(,t ,u)
          expect(result.car).to eq(cons(:_0, cons(:_1)))
        end

        it 'passes frame 1:43' do
          # (run* q (fresh (x) (fresh (y) (==  '( ,x ,y ,x) q)))) ;; => (_0 _1 _0)

          result = run_star('q', fresh('x', fresh('y', unify(cons(x, cons(y, cons(x))), q))))
          # q should be bound to '(,x ,y, ,x)
          expect(result.car).to eq(cons(:_0, cons(:_1, cons(:_0))))
        end

        it "supports 'conj2' relation and passes frame 1:50" do
          # Reasoned S2, frame 1:50
          # (run* q (conj2 succeed succeed)) ;; => (_0)

          result = run_star('q', conj2(succeed, succeed))
          expect(result.car).to eq(:_0)
        end

        it 'passes frame 1:51' do
          # (run* q (conj2 succeed (== 'corn q)) ;; => ('corn)

          result = run_star('q', conj2(succeed, unify(:corn, q)))
          expect(result.car).to eq(:corn)
        end

        it 'passes frame 1:52' do
          # (run* q (conj2 fail (== 'corn q)) ;; => ()

          result = run_star('q', conj2(_fail, unify(:corn, q)))
          expect(result).to be_null
        end

        it 'passes frame 1:53' do
          # Reasoned S2, frame 1:53
          # (run* q (conj2 (== 'corn q)(== 'meal q)) ;; => ()

          result = run_star('q', conj2(unify(:corn, q), unify(:meal, q)))
          expect(result).to be_null
        end

        it 'passes frame 1:54' do
          # (run* q (conj2 (== 'corn q)(== 'corn q)) ;; => ('corn)

          result = run_star('q', conj2(unify(:corn, q), unify(:corn, q)))
          expect(result.car).to eq(:corn)
        end

        it "supports 'disj2' and passes frame 1:55" do
          # (run* q (disj2 fail fail)) ;; => ()

          result = run_star('q', disj2(_fail, _fail))
          expect(result).to be_null
        end

        it 'passes frame 1:56' do
          # (run* q (disj2 (== 'olive q) fail)) ;; => ('olive)

          result = run_star('q', disj2(unify(:olive, q), _fail))
          expect(result.car).to eq(:olive)
        end

        it 'passes frame 1:57' do
          # (run* q (disj2 fail (== 'oil q))) ;; => (oil)

          result = run_star('q', disj2(_fail, unify(:oil, q)))
          expect(result.car).to eq(:oil)
        end

        it 'passes frame 1:58' do
          # (run* q (disj2 (== 'olive q) (== 'oil q))) ;; => (olive oil)

          result = run_star('q', disj2(unify(:olive, q), unify(:oil, q)))
          expect(result.car).to eq(:olive)
          expect(result.cdr.car).to eq(:oil)
        end

        it 'passes frame 1:59' do
          # (run* q (fresh (x) (fresh (y) (disj2  (== '( ,x ,y ) q) (== '( ,x ,y ) q)))))
          # ;; => ((_0 _1) (_0 _1))

          result = run_star('q', fresh('x', (fresh 'y', disj2(unify(cons(x, cons(y)), q), unify(cons(x, cons(y)), q)))))
          # q should be bound to '(,x ,y), then to '(,y ,x)
          expect(result.car).to eq(cons(:_0, cons(:_1)))
          expect(result.cdr.car).to eq(cons(:_0, cons(:_1)))
        end

        it 'passes frame 1:62' do
          # (run* x (disj2
          #           (conj2 (== 'olive x) fail)
          #           (== 'oil x))) ;; => (oil)

          result = run_star('x', disj2(conj2(unify(:olive, x), _fail), unify(:oil, x)))
          expect(result.car).to eq(:oil)
        end

        it 'passes frame 1:63' do
          # (run* x (disj2
          #           (conj2 (== 'olive x) succeed)
          #           ('oil x))) ;; => (olive oil)

          result = run_star('x', disj2(conj2(unify(:olive, x), succeed), unify(:oil, x)))
          expect(result).to eq(cons(:olive, cons(:oil)))
        end

        it 'passes frame 1:64' do
          # (run* x (disj2
          #           (== 'oil x)
          #           (conj2 (== 'olive x) succeed))) ;; => (oil olive)

          result = run_star('x', disj2(unify(:oil, x), conj2(unify(:olive, x), succeed)))
          expect(result).to eq(cons(:oil, cons(:olive)))
        end

        it 'passes frame 1:65' do
          # (run* x (disj2
          #           (conj2(== 'virgin x) fail)
          #           (disj2
          #             (== 'olive x)
          #             (dis2
          #               succeed
          #               (== 'oil x))))) ;; => (olive _0 oil)

          result = run_star('x', disj2(conj2(unify(:virgin, x), _fail),
            disj2(unify(:olive, x), disj2(succeed, unify(:oil, x)))))
          expect(result).to eq(cons(:olive, cons(:_0, cons(:oil))))
          expect(result.to_s).to eq('(:olive _0 :oil)')
        end

        it 'passes frame 1:67' do
          # (run* r
          #   (fresh x
          #     (fresh y
          #       (conj2
          #           (== 'split x)
          #           (conj2
          #             (== 'pea y)
          #             (== '(,x ,y) r)))))) ;; => ((split pea))

          result = run_star('r', fresh('x', fresh('y',
            conj2(unify(:split, x),
            conj2(unify(:pea, y), unify(cons(x, cons(y)), r))))))
          expect(result.to_s).to eq('((:split :pea))')
        end

        it 'passes frame 1:68' do
          # (run* r
          #   (fresh x
          #     (fresh y
          #       (conj2
          #         (conj2
          #           (== 'split x)
          #           (== 'pea y)
          #         (== '(,x ,y) r)))))) ;; => ((split pea))

          result = run_star('r', fresh('x', fresh('y',
            conj2(conj2(unify(:split, x), unify(:pea, y)),
              unify(cons(x, cons(y)), r)))))
          expect(result.to_s).to eq('((:split :pea))')
        end

        it 'passes frame 1:70' do
          # (run* r
          #   (fresh (x y)
          #     (conj2
          #       (conj2
          #         (== 'split x)
          #         (== 'pea y)
          #       (== '(,x ,y) r))))) ;; => ((split pea))

          result = run_star('r', fresh(%w[x y], conj2(
            conj2(unify(:split, x), unify(:pea, y)),
            unify(cons(x, cons(y)), r))))
          expect(result.to_s).to eq('((:split :pea))')
        end

        it 'passes frame 1:72' do
          # (run* (r x y)
          #   (conj2
          #     (conj2
          #       (== 'split x)
          #       (== 'pea y))
          #     (== '(,x ,y) r))) ;; => (((split pea) split pea))
          #             o
          #            / \
          #            o  nil
          #          /  \
          #         /    \
          #        /      \
          #       /        \
          #      /          \
          #      o           o
          #     / \         / \
          # split  o   split   o
          #       / \         / \
          #    pea  nil     pea  nil

          result = run_star(%w[r x y], conj2(
            conj2(unify(:split, x), unify(:pea, y)),
            unify(cons(x, cons(y)), r)))
          expect(result.car.car.car).to eq(:split)
          expect(result.car.car.cdr.car).to eq(:pea)
          expect(result.car.car.cdr.cdr).to be_nil
          expect(result.car.cdr.car).to eq(:split)
          expect(result.car.cdr.cdr.car).to eq(:pea)
          expect(result.car.cdr.cdr.cdr).to be_nil
          expect(result.to_s).to eq('(((:split :pea) :split :pea))')
        end

        it 'passes frame 1:75' do
          # (run* (x y)
          #   (conj2
          #     (== 'split x)
          #     (== 'pea y))) ;; => ((split pea))

          result = run_star(%w[x y], conj2(unify(:split, x), unify(:pea, y)))
          expect(result.to_s).to eq('((:split :pea))')
        end

        it 'passes frame 1:76' do
          # (run* (x y)
          #   (disj2
          #     (conj2 (== 'split x) (== 'pea y))
          #     (conj2 (== 'red x) (== 'bean y)))) ;; => ((split pea)(red bean))

          result = run_star(%w[x y], disj2(
            conj2(unify(:split, x), unify(:pea, y)),
            conj2(unify(:red, x), unify(:bean, y))))
          expect(result.to_s).to eq('((:split :pea) (:red :bean))')
          expect(result.car).to eq(list(:split, :pea))
          expect(result.cdr.car).to eq(list(:red, :bean))
        end

        it 'passes frame 1:77' do
          # (run* r
          #   (fresh (x y)
          #     (conj2
          #       (disj2
          #         (conj2 (== 'split x) (== 'pea y))
          #         (conj2 (== 'red x) (== 'bean y)))
          #       (== '(,x ,y soup) r)))) ;; => ((split pea soup) (red bean soup))

          result = run_star('r',
            fresh(%w[x y], conj2(
              disj2(
                conj2(unify(:split, x), unify(:pea, y)),
                conj2(unify(:red, x), unify(:bean, y))),
              unify(cons(x, cons(y, cons(:soup))), r))))
          expect(result.to_s).to eq('((:split :pea :soup) (:red :bean :soup))')
          expect(result.car).to eq(list(:split, :pea, :soup))
          expect(result.cdr.car).to eq(list(:red, :bean, :soup))
        end

        it 'passes frame 1:78' do
          # (run* r
          #   (fresh (x y)
          #     (disj2
          #       (conj2 (== 'split x) (== 'pea y))
          #       (conj2 (== 'red x) (== 'bean y)))
          #     (== '(,x ,y soup) r))) ;; => ((split pea soup) (red bean soup))

          result = run_star('r',
            fresh(%w[x y], [disj2(
              conj2(unify(:split, x), unify(:pea, y)),
              conj2(unify(:red, x), unify(:bean, y))),
              unify(cons(x, cons(y, cons(:soup))), r)]))
          expect(result.to_s).to eq('((:split :pea :soup) (:red :bean :soup))')
        end

        it 'passes frame 1:80' do
          # (run* (x y z)
          #   (disj2
          #     (conj2 (== 'split x) (== 'pea y))
          #     (conj2 (== 'red x) (== 'bean y)))
          #   (== 'soup z)) ;; => ((split pea soup) (red bean soup))

          result = run_star(%w[x y z], [disj2(
            conj2(unify(:split, x), unify(:pea, y)),
            conj2(unify(:red, x), unify(:bean, y))),
            unify(:soup, z)])
          expect(result.car).to eq(list(:split, :pea, :soup))
          expect(result.cdr.car).to eq(list(:red, :bean, :soup))
        end

        it 'passes frame 1:81' do
          # (run* (x y)
          #   (== 'split x)
          #   (== 'pea y)) ;; => ((split pea))

          result = run_star(%w[x y], [unify(:split, x), unify(:pea, y)])
          expect(result.car).to eq(list(:split, :pea))
        end

        it "supports 'defrel' and passes frame 1:82" do
          # (defrel (teacupo t)
          #   (disj2 (== 'tea t) (== 'cup t)))
          expr = disj2(unify(:tea, t), unify(:cup, t))
          result = defrel('teacupo', ['t'], expr)
          expect(result).to be_kind_of(Rela::DefRelation)
          expect(result.name).to eq('teacupo')
          expect(result.formals.size).to eq(1)
          expect(result.formals[0]).to match(/^t_/)
          goal_expr = result.expression
          expect(goal_expr).to be_kind_of(Core::Goal)
          expect(goal_expr.relation).to eq(Rela::Disj2.instance)
        end

        let(:defrel_teacupo) do
          defrel('teacupo', ['t'], disj2(unify(:tea, t), unify(:cup, t)))
        end

        it "supports the invokation of a 'defrel' and passes frame 1:83" do
          # Reasoned S2, frame 1:83
          # (run* x
          #   (teacupo x)) ;; => ((tea cup))

          defrel_teacupo
          result = run_star('x', teacupo(x))

          expect(result).to eq(cons(:tea, cons(:cup)))
        end

        it 'supports booleans and passes frame 1:84' do
          # Reasoned S2, frame 1:84
          # (run* (x y)
          #   (disj2
          #     (conj2 (teacupo x) (== #t y))
          #     (conj2 (== #f x) (== #t y))) ;; => ((#f #t)(tea #t) (cup #t))

          defrel_teacupo
          result = run_star(%w[x y],
            disj2(
              conj2(teacupo(x), unify('#t', y)),
              conj2(unify('#f', x), unify('#t', y))))

          # Order of solutions differs from RS book
          expect(result.car).to eq(cons(:tea, cons(true)))
          expect(result.cdr.car).to eq(cons(:cup, cons(true)))
          expect(result.cdr.cdr.car).to eq(cons(false, cons(true)))
        end

        it 'passes frame 1:85' do
          # (run* (x y)
          #   (teacupo x)
          #   (teacupo y)) ;; => ((tea tea)(tea cup)(cup tea)(cup c))

          defrel_teacupo
          result = run_star(%w[x y], [teacupo(x), teacupo(y)])

          expect(result.car).to eq(cons(:tea, cons(:tea)))
          expect(result.cdr.car).to eq(cons(:tea, cons(:cup)))
          expect(result.cdr.cdr.car).to eq(cons(:cup, cons(:tea)))
          expect(result.cdr.cdr.cdr.car).to eq(cons(:cup, cons(:cup)))
        end

        it 'passes frame 1:86' do
          # (run* (x y)
          #   (teacupo x)
          #   (teacupo x)) ;; => ((tea _0)(cup _0))

          defrel_teacupo
          result = run_star(%w[x y], [teacupo(x), teacupo(x)])
          expect(result.to_s).to eq('((:tea _0) (:cup _0))')
        end

        it 'passes frame 1:87' do
          # (run* (x y)
          #   (disj2
          #     (conj2 (teacupo x) (teacupo x))
          #     (conj2 (== #f x) (teacupo y)))) ;; => ((#f tea)(#f cup)(tea _0)(cup _0))

          defrel_teacupo
          result = run_star(%w[x y], disj2(
              conj2(teacupo(x), teacupo(x)),
              conj2(unify('#f', x), teacupo(y))))

          # Order of solutions differs from RS book
          expected = '((:tea _0) (:cup _0) (false :tea) (false :cup))'
          expect(result.to_s).to eq(expected)
          expect(result.car).to eq(cons(:tea, cons(:_0)))
          expect(result.cdr.car).to eq(cons(:cup, cons(:_0)))
          expect(result.cdr.cdr.car).to eq(cons(false, cons(:tea)))
          expect(result.cdr.cdr.cdr.car).to eq(cons(false, cons(:cup)))
        end

        it 'supports conde and passes frame 1:88 (i)' do
          # (run* (x y)
          #   (conde
          #     ((teacupo x) (teacupo x))
          #     ((== #f x) (teacupo y)))) ;; => ((#f tea)(#f cup)(tea _0)(cup _0))

          defrel_teacupo
          result = run_star(%w[x y], conde(
              [teacupo(x), teacupo(x)],
              [unify('#f', x), teacupo(y)]))

          # Order of solutions differs from RS book
          expected = '((:tea _0) (:cup _0) (false :tea) (false :cup))'
          expect(result.to_s).to eq(expected)
        end

        it 'supports conde and passes frame 1:88 (ii)' do
          # Reasoned S2, frame 1:88 (second part, a rewrite of 1:76)
          # (run* (x y)
          #   (conde
          #     ((== 'split x) (== 'pea y))
          #     ((== 'red x) (== 'bean y)))) ;; => ((split pea)(red bean))
          result = run_star(%w[x y], conde(
            [unify(:split, x), unify(:pea, y)],
            [unify(:red, x), unify(:bean, y)]))

          expected = '((:split :pea) (:red :bean))'
          expect(result.to_s).to eq(expected)
        end

        it 'passes frame 1:89' do
          # Reasoned S2, frame 1:89 (rewrite of 1:62)
          # (run* x
          #   (conde
          #     ((== 'olive x) fail)
          #     ('oil x))) ;; => (oil)

          result = run_star('x', conde(
            [unify(:olive, x), _fail],
            unify(:oil, x)))

          expect(result.to_s).to eq('(:oil)')
        end

        it 'passes frame 1:90' do
          # (run* (x y)
          #   (conde
          #     ((fresh (z)
          #       (== 'lentil z)))
          #     ((== x y)))) ;; => ((_0 _1)(_0 _0))

          result = run_star(%w[x y], conde(
            [fresh(%w[z], unify(:lentil, z))],
            [unify(x, y)]))

          expect(result.to_s).to eq('((_0 _1) (_0 _0))')
        end

        it 'passes frame 1:91' do
          # (run* (x y)
          #   (conde
          #     ((== 'split x) (== 'pea y))
          #     ((== 'red x) (== 'bean y))
          #     ((== 'green x) (== 'lentil y))))
          # ;; => ((split pea)(red bean)(green lentil))
          result = run_star(%w[x y], conde(
            [unify(:split, x), unify(:pea, y)],
            [unify(:red, x), unify(:bean, y)],
            [unify(:green, x), unify(:lentil, y)]))

          expected = '((:split :pea) (:red :bean) (:green :lentil))'
          expect(result.to_s).to eq(expected)
        end
      end # context
    end # describe
  end # module
end # module
